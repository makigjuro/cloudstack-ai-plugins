using FluentValidation.Results;
using Starter.Shared.Infrastructure.Results;

namespace Starter.Orders.Application.Validators;

public static class ValidationResultExtensions
{
    /// <summary>
    /// Converts FluentValidation failures to a single validation <see cref="Error"/>.
    /// The first failure provides the code/message; all failures are listed per property in Details.
    /// </summary>
    public static Error ToValidationError(this ValidationResult validationResult)
    {
        ArgumentNullException.ThrowIfNull(validationResult);

        var first = validationResult.Errors[0];
        var details = validationResult.Errors
            .GroupBy(failure => failure.PropertyName)
            .ToDictionary(group => group.Key, group => group.Select(failure => failure.ErrorMessage).ToArray());

        return Error.Validation(first.ErrorCode, first.ErrorMessage, details);
    }
}
