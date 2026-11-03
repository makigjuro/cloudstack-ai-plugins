using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Starter.Orders.Infrastructure.Persistence;
using Testcontainers.PostgreSql;

namespace Starter.Orders.Tests.Integration;

/// <summary>
/// Hosts the Orders service against a throwaway PostgreSQL container with a test auth scheme.
/// </summary>
public class IntegrationTestFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    public static readonly Guid DefaultTenantId = Guid.NewGuid();

    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:16-alpine")
        .WithDatabase("starter")
        .Build();

    public async ValueTask InitializeAsync()
    {
        await _postgres.StartAsync();
        await ResetDatabaseAsync();
    }

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        await _postgres.DisposeAsync();
        GC.SuppressFinalize(this);
    }

    /// <summary>HttpClient that is authenticated as a user of <paramref name="tenantId"/> (default tenant if omitted).</summary>
    public HttpClient CreateAuthenticatedClient(Guid? tenantId = null)
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Add("Authorization", TestAuthHandler.SchemeName);
        client.DefaultRequestHeaders.Add(TestAuthHandler.TenantHeader, (tenantId ?? DefaultTenantId).ToString());
        return client;
    }

    public async Task ResetDatabaseAsync()
    {
        await using var scope = Services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
        await dbContext.Database.EnsureDeletedAsync();
        await dbContext.Database.EnsureCreatedAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration((_, configuration) =>
            configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:Orders"] = _postgres.GetConnectionString(),
                ["Auth:Authority"] = "https://login.example.test/",
                ["Auth:Audience"] = "api://starter-orders-tests",
            }));

        builder.ConfigureTestServices(services =>
            services.AddAuthentication(TestAuthHandler.SchemeName)
                .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>(TestAuthHandler.SchemeName, null));
    }
}
