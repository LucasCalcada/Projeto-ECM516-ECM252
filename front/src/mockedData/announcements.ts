import type { Announcement, AnnouncementTag } from "../types/Announcement";

const exampleTag: AnnouncementTag = {
  label: "ExampleTag",
  color: "#",
};

const announcements: Announcement[] = [
  {
    title: "Announcement 1",
    content:
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget elementum leo. Phasellus sit amet urna scelerisque, porta orci vel, ullamcorper enim.",
    tags: [exampleTag],
    date: new Date("01-01-2000"),
  },
  {
    title: "Announcement 2",
    content:
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget elementum leo. Phasellus sit amet urna scelerisque, porta orci vel, ullamcorper enim.",
    tags: [exampleTag, exampleTag, exampleTag, exampleTag],
    date: new Date("01-01-2001"),
  },
  {
    title: "Announcement 3",
    content:
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas eget elementum leo. Phasellus sit amet urna scelerisque, porta orci vel, ullamcorper enim.",
    tags: [],
    date: new Date("01-01-2002"),
  },
];

export default announcements;
