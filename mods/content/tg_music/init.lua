--paradise_sightseer.ogg

local TBS = 2 -- time between songs, delay before another song is played

-- songs need to be manually jotted down here
-- must be organized into numeric indexes to utilize randomness
local songs = {
    -- table for song data
    -- name and length (in seconds) required
    {
      name = "paradise_sightseer",
      length = 92.9
    }
}

local getsong -- declare to be used by self
-- used for returning a song to play
-- provide `prevsong` (name of previous song) from `playerfor` player data to prevent song repeats
-- `attempt` will be a number value for assessing whether or not to keep trying to get a song
getsong = function(prevsong, attempt)
    attempt = (attempt or 0) + 1 -- declare attempt as 0 if not existent, add 1
    if #songs == 0 then error("tg_music: no songs, or songs aren't in numerical order, fatal error!") end
    -- get random from 1 to numerical length
    local index = math.random(1, #songs)
    local song = songs[index]
    -- check for issues
    if not song then error("tg_music: no songs could be found") end
    if not song.name then error("tg_music: song lacks name at index "..index) end
    if not song.length then error("tg_music: song '"..song.name.."' lacks length for calculation") end
    -- plrdata check, expects `prevsong` to be a string, if equal to song's name, then try getting a dif song
    -- only do so if attempt is less than 11 (10 tries maximum)
    if prevsong == song.name and attempt < 11 then
        return getsong(prevsong, attempt)
    end
    -- return a song!
    song = table.copy(song) -- copy to prevent modification to main
    -- ensure length is correlated to pitch
    song.pitch = song.pitch or 1
    song.length = song.length/song.pitch -- by dividing length by pitch!
    song.fadeout = song.fadeout or 2 -- fadeout in seconds
    song.gain = song.gain or 0.1 -- default of 0.1
    -- create a "playinglength" for handling fadeout, subtracted by song fade out + 0.3 for better accuracy
    song.playinglength = song.length - (song.fadeout + 0.3)
    return song
end

-- list of players to play songs for (indexes are numbered)
local playingfor = {}

local rtime = 0 -- running time, used for determining when songs should play and stop

-- sets up a song to play
-- requires player data table from `playingfor`
local function playsong(pdata)
    local song = getsong(pdata.prevsong)
    -- used for fade calculations
    song.playinglength = song.length - song.fadeout
    -- play the song!
    song.to_player = pdata.name
    song.id = core.sound_play(song.name, song)
    song.playedat = rtime -- played at this particular timestamp
    -- ensure code knows!
    pdata.song = song
    -- add to prevsong
    pdata.prevsong = song.name
end

-- expects 5.8+ as it won't account for the playing of songs in clients older when paused
-- plays music for players
core.register_globalstep(function(dtime)
    rtime = rtime + dtime
    -- calculate
    for _,pdata in ipairs(playingfor) do -- index, playerdata
        -- song is playing for player
        local song = pdata.song
        if song then
            local songelapsed = rtime - song.playedat -- how many seconds since song was played
            if songelapsed > song.playinglength then
                -- fading this much gain per second
                local fadestep = song.gain/song.fadeout
                -- song's handle, how much gain to fade per second, fade to this amount of gain
                core.sound_fade(song.id, fadestep, 0)
                -- remove song information, but add a waitingtill - what rtime to play another song at)
                pdata.waitingtill = rtime + song.fadeout
                pdata.song = nil
            end
        -- not playing music, let's check if we can
        else
            -- not waiting, or it has been 2 seconds since previous song ending
            if not pdata.waitingtill or (rtime - pdata.waitingtill) > TBS then
                playsong(pdata)
            end
        end
    end
end)

-- add to `playingfor` table, above dtime loop will play song
core.register_on_joinplayer(function(player)
    -- add to table
    playingfor[#playingfor + 1] = {
        plr = player,
        name = player:get_player_name()
    }
end)
