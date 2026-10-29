using Microsoft.AspNetCore.Http;
using HttpResults = Microsoft.AspNetCore.Http.Results;

namespace Starter.Shared.Infrastructure.Results;

/// <summary>
/// Maps <see cref="Result"/> to HTTP responses. Failures become RFC 7807 problem details carrying the
/// error shape <c>{ error, message, errorType }</c>; no stack traces or internals are ever exposed.
/// </summary>
public static class ResultExtensions
{
    public static IResult ToHttpResult(this Result result) =>
        result.IsSuccess ? HttpResults.NoContent() : result.Error.ToProblem();

    public static IResult ToHttpResult<T>(this Result<T> result) =>
        result.IsSuccess ? HttpResults.Ok(result.Value) : result.Error.ToProblem();

    /// <summary>201 Created with a Location header built from the created value.</summary>
    public static IResult ToHttpResult<T>(this Result<T> result, Func<T, string> createdLocation)
    {
        ArgumentNullException.ThrowIfNull(createdLocation);
        return result.IsSuccess
            ? HttpResults.Created(createdLocation(result.Value), result.Value)
            : result.Error.ToProblem();
    }

    public static int ToStatusCode(this ErrorType type) => type switch
    {
        ErrorType.Validation => StatusCodes.Status400BadRequest,
        ErrorType.NotFound => StatusCodes.Status404NotFound,
        ErrorType.Conflict => StatusCodes.Status409Conflict,
        ErrorType.Unauthorized => StatusCodes.Status401Unauthorized,
        ErrorType.Forbidden => StatusCodes.Status403Forbidden,
        ErrorType.Failure => StatusCodes.Status422UnprocessableEntity,
        _ => StatusCodes.Status500InternalServerError,
    };

    private static IResult ToProblem(this Error error)
    {
        var extensions = new Dictionary<string, object?>
        {
            ["error"] = error.Code,
            ["message"] = error.Message,
            ["errorType"] = error.Type.ToString(),
        };

        if (error.Details is not null)
            extensions["errors"] = error.Details;

        return HttpResults.Problem(
            title: error.Message,
            statusCode: error.Type.ToStatusCode(),
            extensions: extensions);
    }
}
