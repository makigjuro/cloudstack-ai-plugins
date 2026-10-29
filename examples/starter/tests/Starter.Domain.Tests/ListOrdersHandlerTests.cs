using Starter.Domain.Entities;
using Starter.Domain.Repositories;
using Starter.Domain.ValueObjects;
using Starter.Orders.Application.Errors;
using Starter.Orders.Application.Queries;
using Starter.Orders.Application.Validators;

namespace Starter.Domain.Tests;

public class ListOrdersHandlerTests
{
    private readonly IOrderQueryRepository _queryRepository;
    private readonly ListOrdersHandler _sut;

    public ListOrdersHandlerTests()
    {
        _queryRepository = Substitute.For<IOrderQueryRepository>();
        _sut = new ListOrdersHandler(_queryRepository, new ListOrdersValidator());
    }

    [Fact]
    public async Task Handle_ValidQuery_ReturnsPagedOrders()
    {
        // Arrange
        var tenantId = new TenantId(Guid.NewGuid());
        IReadOnlyCollection<Order> page =
        [
            Order.Create(tenantId, "Ada Lovelace", 10m),
            Order.Create(tenantId, "Grace Hopper", 20m),
        ];
        _queryRepository.ListAsync(tenantId, 2, 2, Arg.Any<CancellationToken>()).Returns((page, 5));

        // Act
        var result = await _sut.Handle(new ListOrdersQuery(tenantId.Value, PageNumber: 2, PageSize: 2), CancellationToken.None);

        // Assert
        result.Should().BeSuccess();
        result.Value.Items.Should().HaveCount(2);
        result.Value.TotalCount.Should().Be(5);
        result.Value.PageNumber.Should().Be(2);
        result.Value.PageSize.Should().Be(2);
    }

    [Theory]
    [InlineData(0, 20, OrderErrors.InvalidPageNumberCode)]
    [InlineData(1, 0, OrderErrors.InvalidPageSizeCode)]
    [InlineData(1, ListOrdersValidator.MaxPageSize + 1, OrderErrors.InvalidPageSizeCode)]
    public async Task Handle_InvalidPaging_ReturnsValidationFailure(int pageNumber, int pageSize, string expectedCode)
    {
        // Act
        var result = await _sut.Handle(new ListOrdersQuery(Guid.NewGuid(), pageNumber, pageSize), CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(expectedCode);
        await _queryRepository.DidNotReceive().ListAsync(
            Arg.Any<TenantId>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<CancellationToken>());
    }
}
