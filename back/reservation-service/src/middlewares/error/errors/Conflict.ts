import { ApiError } from '..';

const Conflict = new ApiError(409, 'Reservation date is already booked');
export default Conflict;
