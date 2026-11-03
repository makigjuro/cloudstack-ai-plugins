using Starter.Domain.Entities;
using Starter.Domain.Repositories;
using Starter.Orders.Application.Commands;
using Starter.Orders.Application.Errors;
using Starter.Orders.Application.Validators;

namespace Starter.Domain.Tests;

public class CreateOrderHandlerTests
{
    private readonly IOrderRepository _repository;
    private readonly CreateOrderHandler _sut;

    public CreateOrderHandlerTests()
    {
        _repository = Substitute.For<IOrderRepository>();
        _sut = new CreateOrderHandler(_repository, new CreateOrderValidator());
    }

    [Fact]
    public async Task Handle_ValidCommand_ReturnsSuccess()
    {
        // Arrange
        var command = new CreateOrderCommand(Guid.NewGuid(), "Ada Lovelace", 99.95m);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.Should().BeSuccess();
        result.Value.Id.Should().NotBeEmpty();
        await _repository.Received(1).AddAsync(
            Arg.Is<Order>(order => order.Id.Value == result.Value.Id
                && order.TenantId.Value == command.TenantId
                && order.CustomerName == command.CustomerName
                && order.TotalAmount == command.TotalAmount),
            Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-10)]
    public async Task Handle_NonPositiveTotalAmount_ReturnsValidationFailure(decimal totalAmount)
    {
        // Arrange
        var command = new CreateOrderCommand(Guid.NewGuid(), "Ada Lovelace", totalAmount);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.TotalAmountNotPositiveCode);
        await _repository.DidNotReceive().AddAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_BlankCustomerName_ReturnsValidationFailure()
    {
        // Arrange
        var command = new CreateOrderCommand(Guid.NewGuid(), " ", 10m);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.CustomerNameRequiredCode);
    }

    [Fact]
    public async Task Handle_CustomerNameTooLong_ReturnsValidationFailure()
    {
        // Arrange
        var command = new CreateOrderCommand(Guid.NewGuid(), new string('x', Order.CustomerNameMaxLength + 1), 10m);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.CustomerNameTooLongCode);
    }

    [Fact]
    public async Task Handle_MissingTenant_ReturnsValidationFailure()
    {
        // Arrange
        var command = new CreateOrderCommand(Guid.Empty, "Ada Lovelace", 10m);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.Should().BeFailure();
        result.Error.Code.Should().Be(OrderErrors.TenantIdRequiredCode);
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
