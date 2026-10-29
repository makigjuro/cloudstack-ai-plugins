using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Starter.Orders.Application.Contracts;
using Starter.Orders.Application.Errors;

namespace Starter.Orders.Tests.Integration;

[Trait("Category", "Integration")]
public class OrderEndpointsIntegrationTests : IClassFixture<IntegrationTestFactory>, IAsyncLifetime
{
    private readonly IntegrationTestFactory _factory;

    public OrderEndpointsIntegrationTests(IntegrationTestFactory factory)
    {
        _factory = factory;
    }

    public async ValueTask InitializeAsync() => await _factory.ResetDatabaseAsync();

    public ValueTask DisposeAsync()
    {
        GC.SuppressFinalize(this);
        return ValueTask.CompletedTask;
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task CreateOrder_ValidRequest_Returns201WithLocation()
    {
        // Arrange
        var client = _factory.CreateAuthenticatedClient();

        // Act
        var response = await client.PostAsJsonAsync("/api/orders", new CreateOrderRequest("Ada Lovelace", 42.50m), TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var created = await response.Content.ReadFromJsonAsync<CreateOrderResponse>(TestContext.Current.CancellationToken);
        created!.Id.Should().NotBeEmpty();
        response.Headers.Location!.ToString().Should().Be($"/api/orders/{created.Id}");

        var order = await client.GetFromJsonAsync<OrderResponse>(response.Headers.Location, TestContext.Current.CancellationToken);
        order!.CustomerName.Should().Be("Ada Lovelace");
        order.TotalAmount.Should().Be(42.50m);
        order.Status.Should().Be("Pending");
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task CreateOrder_NonPositiveAmount_Returns400WithErrorCode()
    {
        // Arrange
        var client = _factory.CreateAuthenticatedClient();

        // Act
        var response = await client.PostAsJsonAsync("/api/orders", new CreateOrderRequest("Ada Lovelace", 0m), TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await ReadErrorCodeAsync(response)).Should().Be(OrderErrors.TotalAmountNotPositiveCode);
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task GetOrder_UnknownId_Returns404WithErrorCode()
    {
        // Arrange
        var client = _factory.CreateAuthenticatedClient();

        // Act
        var response = await client.GetAsync($"/api/orders/{Guid.NewGuid()}", TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await ReadErrorCodeAsync(response)).Should().Be(OrderErrors.NotFoundCode);
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task GetOrder_OtherTenantsOrder_Returns404()
    {
        // Arrange
        var owner = _factory.CreateAuthenticatedClient();
        var created = await CreateOrderAsync(owner, "Ada Lovelace", 10m);
        var otherTenant = _factory.CreateAuthenticatedClient(Guid.NewGuid());

        // Act
        var response = await otherTenant.GetAsync($"/api/orders/{created.Id}", TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task ListOrders_WithPaging_ReturnsTenantOrdersNewestFirst()
    {
        // Arrange
        var client = _factory.CreateAuthenticatedClient();
        await CreateOrderAsync(client, "First", 10m);
        await CreateOrderAsync(client, "Second", 20m);
        var newest = await CreateOrderAsync(client, "Third", 30m);
        await CreateOrderAsync(_factory.CreateAuthenticatedClient(Guid.NewGuid()), "Other tenant", 40m);

        // Act
        var response = await client.GetAsync("/api/orders?pageNumber=1&pageSize=2", TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var page = await response.Content.ReadFromJsonAsync<OrderListResponse>(TestContext.Current.CancellationToken);
        page!.TotalCount.Should().Be(3);
        page.PageNumber.Should().Be(1);
        page.PageSize.Should().Be(2);
        page.Items.Should().HaveCount(2);
        page.Items.First().Id.Should().Be(newest.Id);
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task ListOrders_InvalidPageSize_Returns400()
    {
        // Arrange
        var client = _factory.CreateAuthenticatedClient();

        // Act
        var response = await client.GetAsync("/api/orders?pageSize=1000", TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await ReadErrorCodeAsync(response)).Should().Be(OrderErrors.InvalidPageSizeCode);
    }

    [Theory]
    [Trait("Category", "Integration")]
    [InlineData("GET", "/api/orders")]
    [InlineData("GET", "/api/orders/00000000-0000-0000-0000-000000000001")]
    [InlineData("POST", "/api/orders")]
    public async Task ApiEndpoints_WithoutCredentials_Return401(string method, string url)
    {
        // Arrange
        var client = _factory.CreateClient();
        using var request = new HttpRequestMessage(new HttpMethod(method), url)
        {
            Content = method == "POST" ? JsonContent.Create(new CreateOrderRequest("Ada", 1m)) : null,
        };

        // Act
        var response = await client.SendAsync(request, TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Theory]
    [Trait("Category", "Integration")]
    [InlineData("/health/live")]
    [InlineData("/health/ready")]
    public async Task HealthEndpoints_Anonymous_Return200(string url)
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(url, TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    private static async Task<CreateOrderResponse> CreateOrderAsync(HttpClient client, string customerName, decimal totalAmount)
    {
        var response = await client.PostAsJsonAsync("/api/orders", new CreateOrderRequest(customerName, totalAmount), TestContext.Current.CancellationToken);
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        return (await response.Content.ReadFromJsonAsync<CreateOrderResponse>(TestContext.Current.CancellationToken))!;
    }

    private static async Task<string?> ReadErrorCodeAsync(HttpResponseMessage response)
    {
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
        return document.RootElement.GetProperty("error").GetString();
    }
}
