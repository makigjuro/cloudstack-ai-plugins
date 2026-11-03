namespace Starter.Orders.Application.Contracts;

/// <summary>Body of <c>POST /api/orders</c>. The tenant comes from the caller's token, never the body.</summary>
public record CreateOrderRequest(string CustomerName, decimal TotalAmount);
