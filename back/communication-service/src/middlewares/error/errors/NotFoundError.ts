import { ApiError } from '..';

const NotFoundError = new ApiError(404, 'Not found');
export default NotFoundError;
