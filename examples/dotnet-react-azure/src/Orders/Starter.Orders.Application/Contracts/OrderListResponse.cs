namespace Starter.Orders.Application.Contracts;

public record OrderListResponse(IReadOnlyCollection<OrderResponse> Items, int TotalCount, int PageNumber, int PageSize);
