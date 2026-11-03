using FluentValidation;
using Starter.Domain.Entities;
using Starter.Domain.Repositories;
using Starter.Domain.ValueObjects;
using Starter.Orders.Application.Contracts;
using Starter.Orders.Application.Validators;
using Starter.Shared.Infrastructure.Results;

namespace Starter.Orders.Application.Commands;

public class CreateOrderHandler
{
    private readonly IOrderRepository _orderRepository;
    private readonly IValidator<CreateOrderCommand> _validator;

    public CreateOrderHandler(IOrderRepository orderRepository, IValidator<CreateOrderCommand> validator)
    {
        _orderRepository = orderRepository;
        _validator = validator;
    }

    public async Task<Result<CreateOrderResponse>> Handle(CreateOrderCommand command, CancellationToken cancellationToken)
    {
        var validation = await _validator.ValidateAsync(command, cancellationToken);
        if (!validation.IsValid)
            return Result.Failure<CreateOrderResponse>(validation.ToValidationError());

        var order = Order.Create(new TenantId(command.TenantId), command.CustomerName, command.TotalAmount);

        await _orderRepository.AddAsync(order, cancellationToken);
        await _orderRepository.SaveChangesAsync(cancellationToken);

        return Result.Success(new CreateOrderResponse(order.Id.Value));
    }
}
