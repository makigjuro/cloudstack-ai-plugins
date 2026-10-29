using Starter.Domain.Entities;

namespace Starter.Orders.Application.Contracts;

internal static class OrderMappings
{
    public static OrderResponse ToResponse(this Order order) =>
        new(order.Id.Value, order.CustomerName, order.TotalAmount, order.Status.ToString(), order.CreatedAt);
}
