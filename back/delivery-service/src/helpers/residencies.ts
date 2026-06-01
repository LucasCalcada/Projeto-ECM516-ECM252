import axios from 'axios';
import config from '@app/config';
import BadRequest from '@app/middlewares/error/errors/BadRequest';
import NotFoundError from '@app/middlewares/error/errors/NotFoundError';

interface ResidencyDetails {
  id: string;
  name: string | null;
}

interface NamedResidencyDetails {
  id: string;
  name: string;
}

interface ResidencyGroupDetails {
  residencies: ResidencyDetails[];
}

interface BuildingDetailsResponse {
  residentData: ResidencyGroupDetails[];
}

function normalizeResidencyName(name: string) {
  return name.trim().toLowerCase();
}

export async function resolveResidencyByName(
  buildingId: string,
  residencyName: string,
  token: string,
) {
  const normalizedName = normalizeResidencyName(residencyName);

  if (!normalizedName) {
    throw BadRequest;
  }

  const response = await axios.get<BuildingDetailsResponse>(
    `${config.coreServiceUrl}/building/${buildingId}/details`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  );

  const residencies = response.data.residentData.flatMap((group) => group.residencies);
  const matches = residencies.filter(
    (residency): residency is NamedResidencyDetails =>
      residency.name !== null && normalizeResidencyName(residency.name) === normalizedName,
  );

  if (matches.length === 0) {
    throw NotFoundError;
  }

  if (matches.length > 1) {
    throw BadRequest;
  }

  return {
    residencyId: matches[0].id,
    residencyName: matches[0].name,
  };
}
