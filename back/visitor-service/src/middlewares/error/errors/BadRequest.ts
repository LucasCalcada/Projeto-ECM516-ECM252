import { ApiError } from '..';

const BadRequest = new ApiError(400, 'Bad Request');
export default BadRequest;
