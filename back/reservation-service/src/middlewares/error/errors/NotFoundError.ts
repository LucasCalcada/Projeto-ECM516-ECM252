import { ApiError } from '..';

const NotFoundError = new ApiError(404, 'Not Found');
export default NotFoundError;
