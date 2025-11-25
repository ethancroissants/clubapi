local server = require("http").server.new()
local airtable = require("utils/airtable")
local url = require("utils/urlparams")
local auth = require("utils/auth")


server:get("/", function()
    return {status = 200, response = "Clubs API", routes = {"/clubs", "/clubs/:id"}}
end)


server:get("/clubs", function(req)
    pprint(req:headers())
        return {totalClubs  = airtable.list_records("Clubs", "Ivie ByID").records[1].fields.id}
    end)

server:get("/club", function(req)
    local params = url.parse_query(req:uri())
    local formula = "{club_name} = " .. params.name
    local fields = {"Est. # of Attendees", "call_meeting_days", "call_meeting_length", "club_name", "club_status", "id", "leader_slack_id", "level", "venue_address_country"}
    local club = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
    return club
end)

server:get("/leader", function(req)
    local params = url.parse_query(req:uri())
    local formula = "{email} = " .. params.email
    local fields = {"rel_leader_to_clubs", "rel_co_leader_to_clubs"}
    local leader = airtable.list_records("Leaders", "Grid view", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
    local club = nil
    if leader.fields.rel_leader_to_clubs then
        club = leader.fields.rel_leader_to_clubs[1]
    elseif leader.fields.rel_co_leader_to_clubs then
        club = leader.fields.rel_co_leader_to_clubs[1]
    end
    local club_name = airtable.get_record("Clubs", club).fields.club_name
    return {club_name = club_name}
end)

server:get("/ships", function(req)
    local params = url.parse_query(req:uri())
    local formula = "{club_name (from Clubs)} = " .. params.club_name
    local fields = {"workshop", "Rating", "code_url", "club_name (from Clubs)", "YSWS–Name (from Unified YSWS Database)"}
    local ships = airtable.list_records("Club Ships", "Grid view", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records
    return ships
end)

server:get("/level", function(req)
    local params = url.parse_query(req:uri())
    local formula = "{club_name} = " .. params.club_name
    local fields = {"level"}
    local level = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1].fields.level 
    return {level = level}  
end)



server.port = 3000
pprint("Server running on port 3000")
server:run()
