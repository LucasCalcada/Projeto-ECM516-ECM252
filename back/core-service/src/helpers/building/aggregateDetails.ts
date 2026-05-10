interface Row {
  groupId: string;
  groupName: string | null;
  residencyId: string;
  residencyName: string | null;
  residencyCode: string | null;
  userId: string | null;
  userName: string | null;
}

interface UserDetails {
  id: string;
  name: string | null;
}

interface ResidencyDetails {
  id: string;
  name: string | null;
  code: string | null;
  users: Record<string, UserDetails>;
}

interface GroupDetails {
  id: string;
  name: string | null;
  residencies: Record<string, ResidencyDetails>;
}

function groupData(data: Row[]) {
  return data.reduce<Record<string, GroupDetails>>((acc, row) => {
    // Adds group to object
    let group = acc[row.groupId];

    if (group == undefined) {
      acc[row.groupId] = {
        id: row.groupId,
        name: row.groupName,
        residencies: {},
      };
      group = acc[row.groupId];
    }

    // Adds residency to group
    let residency = group.residencies[row.residencyId];
    if (residency == undefined) {
      group.residencies[row.residencyId] = {
        id: row.residencyId,
        name: row.residencyName,
        code: row.residencyCode,
        users: {},
      };
      residency = group.residencies[row.residencyId];
    }

    if (row.userId == null) return acc;

    // Adds user to residency
    const user = residency.users[row.userId];
    if (user == undefined) {
      residency.users[row.userId] = {
        id: row.userId,
        name: row.userName,
      };
    }

    return acc;
  }, {});
}

function intoArrays(data: Record<string, GroupDetails>) {
  return Object.values(data).map((group) => ({
    id: group.id,
    name: group.name,
    residencies: Object.values(group.residencies).map((residency) => ({
      id: residency.id,
      name: residency.name,
      code: residency.code,
      users: Object.values(residency.users).map((user) => ({
        id: user.id,
        name: user.name,
      })),
    })),
  }));
}

export default function aggregateDetails(data: Row[]) {
  const groupedData = groupData(data);
  return intoArrays(groupedData);
}
