using Starter.Shared.Infrastructure.Results;

namespace Starter.Orders.Application.Errors;

/// <summary>
/// Entity-specific error codes for the Order aggregate (SCREAMING_SNAKE_CASE).
/// </summary>
public static class OrderErrors
{
    public const string NotFoundCode = "ORDER_NOT_FOUND";
    public const string TenantIdRequiredCode = "TENANT_ID_REQUIRED";
    public const string OrderIdRequiredCode = "ORDER_ID_REQUIRED";
    public const string CustomerNameRequiredCode = "ORDER_CUSTOMER_NAME_REQUIRED";
    public const string CustomerNameTooLongCode = "ORDER_CUSTOMER_NAME_TOO_LONG";
    public const string TotalAmountNotPositiveCode = "ORDER_TOTAL_AMOUNT_NOT_POSITIVE";
    public const string InvalidPageNumberCode = "ORDER_INVALID_PAGE_NUMBER";
    public const string InvalidPageSizeCode = "ORDER_INVALID_PAGE_SIZE";

    public static Error NotFound(Guid orderId) =>
        Error.NotFound(NotFoundCode, $"Order '{orderId}' was not found.");
}
