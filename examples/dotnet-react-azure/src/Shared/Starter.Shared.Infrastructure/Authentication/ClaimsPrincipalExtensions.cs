using System.Security.Claims;

namespace Starter.Shared.Infrastructure.Authentication;

public static class ClaimsPrincipalExtensions
{
    /// <summary>Returns the caller's tenant ID, or <see cref="Guid.Empty"/> when the claim is missing or malformed.</summary>
    public static Guid GetTenantId(this ClaimsPrincipal principal)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var value = principal.FindFirstValue(StarterClaimTypes.TenantId);
        return Guid.TryParse(value, out var tenantId) ? tenantId : Guid.Empty;
    }
}
