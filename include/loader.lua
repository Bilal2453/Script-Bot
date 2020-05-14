local fs = require 'fs'
local pathJoin = require 'pathjoin'.pathJoin
local new_fs_event = require 'uv'.new_fs_event

local stat, exists, scandir, readfile = fs.statSync, fs.existsSync, fs.scandirSync, fs.readFileSync

local module = {}

local function call(c, ...)
	if type(c) == "function" then
		return pcall(c, ...)
	end
	return
end

local function read(p, ...)
	for _, v in ipairs{...} do
		p = pathJoin(p, v)
	end

	local fileData, errmsg = readfile(p)

	if not fileData then
		return false, errmsg
	end

	return fileData
end


local function watch(path, callback)
	local stats = {}
	local oldStat = stat(path)
	local isFile = oldStat.type == 'file'
	local function rPath(p, n) return isFile and p or pathJoin(p, n) end

	if isFile then
		stats[path] = oldStat
	else
		local joined
		for name in scandir(path) do
			joined = pathJoin(path, name)
			stats[joined] = stat(joined)
		end
	end

	local fsEvent = new_fs_event()
	fsEvent:start(path, {}, function(err, name, event)
		if err then logger:log(1, err) return end

		if not event.change then
			local newPath = rPath(path, name)

			-- NOTE: event.rename will be emitted even on delete-
			-- but on the real rename event two event.rename will be emitted
			-- omg please luvit fix that, this code should handle both
			if not exists(newPath) then -- File Deleted?
				stats[newPath] = nil -- Remove old stats
			else -- File Created?
				stats[newPath] = stat(newPath) -- Add the new stats
			end

			return
		end

		local filePath = rPath(path, name)
		local old = stats[filePath]
		local new = stat(filePath)

		stats[filePath] = new

		if new.size ~= 0 and (old.mtime.sec ~= new.mtime.sec or old.mtime.nsec ~= new.mtime.nsec) then
			return callback(name)
		end
	end)

	return fsEvent
end

-- TODO: Better and Cleaner loader... this one is just ugly and buggy.
local function loadDirec(direc, filesPattern, spaceName, baseMesg, beforeExec, afterExec)
	spaceName = spaceName and spaceName.. ' : ' or ''

	local function loadFile(name)
		local filePath = pathJoin(direc, name)

		local oName = name
		name = name:gsub(filesPattern, '')

		if not exists(filePath) then
			logger:log(1, 'Attempt to find "%s" %s', name, baseMesg)
			return
		end

		call(beforeExec, name)

		local succ, result = read(filePath)
		if not succ then
			logger:log(1, 'Attempt to read "%s" : %s', filePath, result)
			return
		end

		local runtimeSuccess, loader, errMesg = call(load, succ, oName, 't', env)
		succ, result = call(loader)

		runtimeSuccess = runtimeSuccess and loader
		if not (runtimeSuccess and succ) then
			logger:log(1, 'Attempt to load "%s" %s :\n\t\t\t\t  %s', name, baseMesg,
				tostring(runtimeSuccess and result or loader or errMesg)
			)
			return
		end

		call(afterExec, name, result)

		logger:log(3, '%sSuccesfuly loaded "%s" %s', spaceName, name, baseMesg)
	end

	local function loadAll()
		for filePath in scandir(direc) do
			if filePath:find(filesPattern) then
				loadFile(filePath)
			end
		end
	end

	loadAll()

	-- Watch for changes and reload
	local e = watch(direc, function(name)
		if not name:find(filesPattern) then return end
		if not exists(pathJoin(direc, name)) then return end

		loadFile(name)
	end)

	return loadAll, e
end


module.loadDirec = loadDirec
module.watch = watch

return module
