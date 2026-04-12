interface Row {
  groupId: string;
  groupName: string | null;
  residencyId: string;
  residencyName: string | null;
  residencyCode: string | null;
  userId: string | null;
  userName: string | null;
}

function groupData(data: Row[]) {
  return data.reduce((acc: any, row: Row) => {
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

function intoArrays(data: any[]) {
  return Object.values(data).map((group) => ({
    id: group.id,
    name: group.name,
    residencies: Object.values(group.residencies).map((residency: any) => ({
      id: residency.id,
      name: residency.name,
      code: residency.code,
      users: Object.values(residency.users).map((user: any) => ({
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
