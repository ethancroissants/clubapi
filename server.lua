local server = require("http").server.new()
local airtable = require("utils/airtable")
local url = require("utils/urlparams")
local auth = require("utils/auth")
local log = require("utils/logging")


-----------------
-- GET RECORDS --
-----------------


server:static_file("/", "docs.html")


-- CLUB MANAGEMENT

server:get("/clubs", function(req)
    return {totalClubs  = airtable.list_records("Clubs", "Ivie ByID").records[1].fields.id}
end)

server:get("/clubs/country", function(req)
    log.request(req:uri(), req:headers())
    local params = url.parse_query(req:uri())
    local formula = "{venue_address_country} = " .. params.country
    return {clubs  = airtable.count_records("Clubs", formula)}
end)

server:get("/club", function(req)
    log.request(req:uri(), req:headers())
if auth.checkRead(req:headers().authorization) == false then
    local params = url.parse_query(req:uri())
    local formula = "{club_name} = " .. params.name
    local fields = {"Est. # of Attendees", "call_meeting_days", "call_meeting_length", "club_name", "club_status", "id", "leader_slack_id", "level", "venue_address_country"}
    local club = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
    if club == nil then
        return {club_name = nil}
    end
    return club
else 
    local params = url.parse_query(req:uri())
    local formula = "{club_name} = " .. params.name
    local club = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York"}).records[1]
    if club == nil then
        return {club_name = nil}
    end
    return club
end
end)

-- LEADER MANAGEMENT 

server:get("/leader", function(req)
    log.request(req:uri(), req:headers())
if auth.checkRead(req:headers().authorization) then
    local params = url.parse_query(req:uri())
    local formula = "{email} = " .. params.email
    local fields = {"rel_leader_to_clubs", "rel_co_leader_to_clubs"}
    local leader = airtable.list_records("Leaders", "Grid view", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
    local club = nil
    if leader == nil then
        return {club_name = nil}
    end
    if leader.fields.rel_leader_to_clubs then
        club = leader.fields.rel_leader_to_clubs[1]
    elseif leader.fields.rel_co_leader_to_clubs then
        club = leader.fields.rel_co_leader_to_clubs[1]
    end
    local club_name = airtable.get_record("Clubs", club).fields.club_name
    return {club_name = club_name}
else 
    local params = url.parse_query(req:uri())
    local formula = "{email} = " .. params.email
    local fields = {"rel_leader_to_clubs", "rel_co_leader_to_clubs"}
    local leader = airtable.list_records("Leaders", "Grid view", {filterByFormula = formula, timeZone = "America/New_York", fields = fields})
    if leader.records[1] == nil then
        return {leader = false}
    else 
        return {leader = true}
    end
end
end)

-- SHIP MANAGEMENT

server:get("/ships", function(req)
    log.request(req:uri(), req:headers())
if auth.checkRead(req:headers().authorization) == false then
    local params = url.parse_query(req:uri())
    local formula = "{club_name (from Clubs)} = " .. params.club_name
    local fields = {"workshop", "Rating", "code_url", "club_name (from Clubs)", "YSWS–Name (from Unified YSWS Database)"}
    local ships = airtable.list_records("Club Ships", "Grid view", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records
    return ships
else 
    local params = url.parse_query(req:uri())
    local formula = "{club_name (from Clubs)} = " .. params.club_name
    local ships = airtable.list_records("Club Ships", "Grid view", {filterByFormula = formula, timeZone = "America/New_York"}).records
    return ships
end
end)

-- MEMBERS MANAGEMENT

server:get("/members", function(req)
    log.request(req:uri(), req:headers())
    if auth.checkRead(req:headers().authorization) then
        local params = url.parse_query(req:uri())
        local formula = "{club_name} = " .. params.club_name
        local fields = {"Members"}
        local club = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
        if club == nil then
            return {error = "Club not found"}
        end
        local memberIds = club.fields.Members
        if memberIds == nil then
            return {members = {}}
        end
        local memberNames = {}
        for _, memberId in ipairs(memberIds) do
            local member = airtable.get_record("Members", memberId)
            table.insert(memberNames, member.fields.Name)
        end
        return {members = memberNames}
    else
        return {error = "Unauthorized"}
    end
end)

-- LEVEL/STATUS MANAGEMENT

server:get("/level", function(req)
    log.request(req:uri(), req:headers())
    local params = url.parse_query(req:uri())
    local formula = "{club_name} = " .. params.club_name
    local fields = {"level"}
    local level = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
    if level == nil then
        return {level = "No club found"}
    end
    return {level = level.fields.level}  
end)

server:get("/status", function(req)
    log.request(req:uri(), req:headers())
    local params = url.parse_query(req:uri())
    local formula = "{club_name} = " .. params.club_name
    local fields = {"club_status"}
    local status = airtable.list_records("Clubs", "Full Grid", {filterByFormula = formula, timeZone = "America/New_York", fields = fields}).records[1]
    if status == nil then
        return {status = "No club found"}
    end
    return {status = status.fields.club_status}  
end)

------------------
-- POST RECORDS --
------------------

-- LEADER MANAGEMENT 

server:post("/leader", function(req)
    log.request(req:uri(), req:headers())
if auth.checkWrite(req:headers().authorization) then
    local params = url.parse_query(req:uri())
    local email = params.email
    local new_email = params.new_email
    if email == nil or new_email == nil then
        return {error = "Missing email"}
    end
    local formula = "{email} = " .. email
    local leader = airtable.list_records("Leaders", "Grid view", {filterByFormula = formula}).records[1]
    if leader == nil then
        return {error = "Leader not found"}
    end
    local id = leader.id
    local updateLeader = airtable.update_record("Leaders", id, {email = url.strip_quotes(new_email)})
    return {new_email = updateLeader.fields.email}
else 
    return {error = "Unauthorized"}
end
end)

-- LEVEL/STATUS MANAGEMENT

server:post("/status", function(req)
    log.request(req:uri(), req:headers())
if auth.checkWrite(req:headers().authorization) then
    local params = url.parse_query(req:uri())
    local status = params.status
    local club_name = params.club_name
    if status == nil or club_name == nil then
        return {error = "Missing parameters"}
    end
    local formula = "{club_name} = " .. club_name
    local club = airtable.list_records("Clubs", "Full Grid View", {filterByFormula = formula}).records[1]
    if club == nil then
        return {error = "Club not found"}
    end
    local id = club.id
    local updateClub = airtable.update_record("Clubs", id, {club_status = url.strip_quotes(status)})
    return {new_status = updateClub.fields.club_status}
else 
    return {error = "Unauthorized"}
end
end)

server:post("/level", function(req)
    log.request(req:uri(), req:headers())
if auth.checkWrite(req:headers().authorization) then
    local params = url.parse_query(req:uri())
    local level = params.level
    local club_name = params.club_name
    if level == nil or club_name == nil then
        return {error = "Missing parameters"}
    end
    local formula = "{club_name} = " .. club_name
    local club = airtable.list_records("Clubs", "Full Grid View", {filterByFormula = formula}).records[1]
    if club == nil then
        return {error = "Club not found"}
    end
    local id = club.id
    local updateClub = airtable.update_record("Clubs", id, {level = url.strip_quotes(level)})
    return {new_level = updateClub.fields.level}
else 
    return {error = "Unauthorized"}
end
end)

server.port = os.getenv("PORT")
server.hostname = os.getenv("HOST")
pprint("Server running on port " .. server.port .. " at " .. server.hostname)
server:run()
