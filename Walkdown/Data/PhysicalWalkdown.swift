import Foundation

extension TemplateLibrary {
    /// An original checklist for walking a site in person.
    static let physicalWalkdown = ChecklistTemplate(
        id: "physical-walkdown",
        name: "Physical Security Walkdown",
        summary: "What you can see and test walking the site: entry, server rooms, desks, wireless, and disposal.",
        source: "Walkdown original checklist",
        groups: [
            TemplateGroup(name: "Perimeter and Entry", items: [
                TemplateItem(id: "PW-1.1", title: "Entry points are controlled",
                             guidance: "Exterior doors lock, badge readers work, and propped or broken doors are not present."),
                TemplateItem(id: "PW-1.2", title: "Visitors sign in and are escorted",
                             guidance: "There is a visitor log or system, visitors get badges, and someone escorts them past the lobby."),
                TemplateItem(id: "PW-1.3", title: "Tailgating is prevented",
                             guidance: "Watch the main entrance for a few minutes. Note whether people hold doors for others without checking badges."),
                TemplateItem(id: "PW-1.4", title: "Badges are worn and visible",
                             guidance: "Staff wear badges in secure areas. Ask a couple of people what they would do if they saw someone without one."),
                TemplateItem(id: "PW-1.5", title: "Cameras cover key areas",
                             guidance: "Entrances, the server room, and loading areas are covered. Ask how long footage is kept and who reviews it."),
            ]),
            TemplateGroup(name: "Server and Network Rooms", items: [
                TemplateItem(id: "PW-2.1", title: "Server room is locked and access limited",
                             guidance: "The door is locked, access is restricted to named people, and entry is logged."),
                TemplateItem(id: "PW-2.2", title: "Network closets are secured",
                             guidance: "Wiring closets and IDF rooms are locked, not used as storage, and racks are closed."),
                TemplateItem(id: "PW-2.3", title: "Environmental protections are in place",
                             guidance: "Look for cooling, fire suppression, water detection, and UPS units that are working and maintained."),
                TemplateItem(id: "PW-2.4", title: "No unattended consoles",
                             guidance: "Rack consoles and KVMs are locked or logged out. No admin sessions are left open."),
                TemplateItem(id: "PW-2.5", title: "Equipment is labeled and tidy",
                             guidance: "Gear and cables are labeled, and there are no unknown or unmanaged devices plugged in."),
            ]),
            TemplateGroup(name: "Workspaces", items: [
                TemplateItem(id: "PW-3.1", title: "Screens lock when unattended",
                             guidance: "Walk the floor and check for unlocked, unattended workstations."),
                TemplateItem(id: "PW-3.2", title: "No passwords on display",
                             guidance: "Check monitors, keyboards, and whiteboards for written passwords or sticky notes."),
                TemplateItem(id: "PW-3.3", title: "Clean desk practice is followed",
                             guidance: "Sensitive printouts and files are not left out on desks, printers, or shared tables."),
                TemplateItem(id: "PW-3.4", title: "Screens facing public areas are protected",
                             guidance: "Monitors visible from windows or the lobby use privacy filters or are turned away."),
                TemplateItem(id: "PW-3.5", title: "Laptops are secured",
                             guidance: "Laptops left overnight are locked in drawers or cabled. Ask about the policy for travel."),
            ]),
            TemplateGroup(name: "Network and Wireless", items: [
                TemplateItem(id: "PW-4.1", title: "Public network jacks are disabled",
                             guidance: "Wall jacks in the lobby, conference rooms, and other public spaces are disabled or isolated."),
                TemplateItem(id: "PW-4.2", title: "Guest Wi-Fi is separated",
                             guidance: "The guest network is isolated from internal systems and uses a password that changes."),
                TemplateItem(id: "PW-4.3", title: "No rogue wireless devices",
                             guidance: "Look for unknown access points, personal routers, or hotspots on desks and in closets."),
                TemplateItem(id: "PW-4.4", title: "Printers and IoT devices are managed",
                             guidance: "Printers, cameras, and smart devices have changed default passwords and are on a separate network where possible."),
            ]),
            TemplateGroup(name: "Media and Disposal", items: [
                TemplateItem(id: "PW-5.1", title: "Shred bins are used and locked",
                             guidance: "Locked shred bins are available, and sensitive paper is not going into regular trash or recycling."),
                TemplateItem(id: "PW-5.2", title: "Old drives and devices are disposed of securely",
                             guidance: "Ask how retired drives and devices are wiped or destroyed, and ask for certificates of destruction."),
                TemplateItem(id: "PW-5.3", title: "Removable media is controlled",
                             guidance: "USB drives are restricted or tracked. Look for loose drives and backup tapes."),
                TemplateItem(id: "PW-5.4", title: "Backup media is stored securely",
                             guidance: "Backups are locked up, stored away from the primary site, and access is limited."),
            ]),
        ]
    )
}
