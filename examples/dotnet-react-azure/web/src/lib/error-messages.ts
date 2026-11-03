import { isApiError } from '@/api/client'

/**
 * Maps any thrown error to a user-facing message.
 * Raw server messages and stack traces are never shown to users.
 */
export function getErrorMessage(error: unknown): string {
  if (!isApiError(error)) return 'Something went wrong. Please try again.'

  switch (error.code) {
    case 'network':
      return 'Cannot reach the server. Check your connection and try again.'
    case 'bad_request':
      return 'The request was rejected. Please check the values and try again.'
    case 'unauthorized':
      return 'Your session has expired. Please sign in again.'
    case 'forbidden':
      return 'You do not have access to this resource.'
    case 'not_found':
      return 'The requested item could not be found.'
    case 'conflict':
      return 'This item was changed by someone else. Reload and try again.'
    case 'server':
      return 'The server encountered an error. Please try again later.'
    case 'unknown':
      return 'Something went wrong. Please try again.'
  }
}
