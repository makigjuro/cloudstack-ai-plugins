namespace Starter.Shared.Infrastructure.Authentication;

public static class StarterClaimTypes
{
    /// <summary>Tenant claim; matches the <c>tid</c> claim issued by Microsoft Entra ID.</summary>
    public const string TenantId = "tid";

    public const string Subject = "sub";

    public const string Name = "name";
}
