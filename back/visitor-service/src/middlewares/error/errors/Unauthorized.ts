import { ApiError } from '..';

const Unauthorized = new ApiError(401, 'Unauthorized');
export default Unauthorized;
