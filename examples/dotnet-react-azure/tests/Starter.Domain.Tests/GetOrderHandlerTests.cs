using Starter.Domain.Entities;
using Starter.Domain.Repositories;
using Starter.Domain.ValueObjects;
using Starter.Orders.Application.Errors;
using Starter.Orders.Application.Queries;
using Starter.Orders.Application.Validators;

namespace Starter.Domain.Tests;

public class GetOrderHandlerTests
{
    private readonly IOrderQueryRepository _queryRepository;
    private readonly GetOrderHandler _sut;

    public GetOrderHandlerTests()
    {
        _queryRepository = Substitute.For<IOrderQueryRepository>();
        _sut = new GetOrderHandler(_queryRepository, new GetOrderValidator());
    }

    [Fact]
    public async Task Handle_OrderExists_ReturnsOrder()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var order = Order.Create(new TenantId(tenantId), "Ada Lovelace", 12.34m);
        _queryRepository.GetByIdAsync(order.Id, Arg.Any<CancellationToken>()).Returns(order);

        // Act
        var result = await _sut.Handle(new GetOrderQuery(tenantId, order.Id.Value), CancellationToken.None);

        // Assert
        result.Should().BeSuccess();
        result.Value.Id.Should().Be(order.Id.Value);
        result.Value.CustomerName.Should().Be("Ada Lovelace");
        result.Value.TotalAmount.Should().Be(12.34m);
        result.Value.Status.Should().Be(nameof(OrderStatus.Pending));
    }

    [Fact]
    public async Task Handle_NotFound_ReturnsFailure()
    {
        // Arrange
        _queryRepository.GetByIdAsync(Arg.Any<OrderId>(), Arg.Any<CancellationToken>())
            .Returns((Order?)null);

        // Act
        var result = await _sut.Handle(new GetOrderQuery(Guid.NewGuid(), Guid.NewGuid()), CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.NotFoundCode);
    }

    [Fact]
    public async Task Handle_OrderOfAnotherTenant_ReturnsNotFound()
    {
        // Arrange
        var order = Order.Create(new TenantId(Guid.NewGuid()), "Ada Lovelace", 12.34m);
        _queryRepository.GetByIdAsync(order.Id, Arg.Any<CancellationToken>()).Returns(order);

        // Act
        var result = await _sut.Handle(new GetOrderQuery(Guid.NewGuid(), order.Id.Value), CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.NotFoundCode);
    }

    [Fact]
    public async Task Handle_EmptyId_ReturnsValidationFailure()
    {
        // Act
        var result = await _sut.Handle(new GetOrderQuery(Guid.NewGuid(), Guid.Empty), CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.OrderIdRequiredCode);
        await _queryRepository.DidNotReceive().GetByIdAsync(Arg.Any<OrderId>(), Arg.Any<CancellationToken>());
    }
}
