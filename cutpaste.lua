-- Cut & Paste for Marta
-- Cmd+X marks the selected files for moving and copies them to the clipboard.
-- Cmd+V moves marked files into the current folder (or does a normal paste
-- if nothing is marked). Cmd+C clears any pending cut and copies normally.

plugin {
    id = "cutpaste",
    name = "Cut and Paste",
    apiVersion = "2.2"
}

-- Pending cut: list of { file = File, raw = "/abs/path", name = "file" }
local pending = nil

local function log(msg) print("[cutpaste] " .. msg) end

local function getGlobalContext()
    if marta and marta.globalContext then return marta.globalContext end
    return globalContext
end

local function runCoreAction(context, id)
    local a = getGlobalContext().actions:getById(id)
    if a then a:apply(context) end
end

-- Run fn, and show any Lua error in an alert instead of failing silently
local function guarded(fn)
    return function(context)
        local ok, e = pcall(fn, context)
        if not ok then
            log("ERROR: " .. tostring(e))
            martax.alert("cutpaste error: " .. tostring(e))
        end
    end
end

action {
    id = "cut",
    name = "Cut",
    apply = guarded(function(context)
        local files = context.activePane.model.activeFiles
        if not files or #files == 0 then return end

        pending = {}
        for _, f in ipairs(files) do
            table.insert(pending, { file = f, raw = f.path.rawValue, name = f.name })
            log("cut " .. f.path.rawValue)
        end
        -- Put the files on the clipboard exactly like a normal copy would
        runCoreAction(context, "core.clipboard.copy")
    end)
}

action {
    id = "copy",
    name = "Copy (clears pending cut)",
    apply = guarded(function(context)
        pending = nil
        runCoreAction(context, "core.clipboard.copy")
    end)
}

action {
    id = "paste",
    name = "Paste (moves if cut)",
    apply = guarded(function(context)
        if not pending or #pending == 0 then
            runCoreAction(context, "core.clipboard.paste")
            return
        end

        local model = context.activePane.model
        local folder = model.folder
        if not folder then return end
        local destDirPath = folder.path
        local destDir = destDirPath.rawValue

        local skipped = {}
        for _, item in ipairs(pending) do
            local src = item.raw
            local srcParent = item.file.parent and item.file.parent.path.rawValue or ""
            local destPath = destDirPath:resolve(item.name)
            local destFile = folder:resolve(item.name)

            if srcParent == destDir then
                -- Pasting into the same folder: nothing to do
            elseif destDir == src or destDir:sub(1, #src + 1) == src .. "/" then
                table.insert(skipped, item.name .. " (can't move a folder into itself)")
            elseif destFile:exists() then
                table.insert(skipped, item.name .. " (already exists here)")
            elseif not item.file:exists() then
                table.insert(skipped, item.name .. " (original no longer exists)")
            else
                log("move " .. src .. " -> " .. destPath.rawValue)
                local sameVolume = item.file:isOnSameVolume(folder)
                local err = nil
                if sameVolume then
                    err = item.file:rename(destPath)
                end
                if err or not sameVolume then
                    -- Different volume (or rename failed): mv copies, then deletes the original
                    log("falling back to mv (" .. tostring(err) .. ")")
                    martax.execute("/bin/mv", { "-n", src, destDir .. "/" })
                end
            end
        end

        pending = nil
        pcall(function() model:refresh(true, nil) end)

        if #skipped > 0 then
            martax.alert("Some items were not moved:\n" .. table.concat(skipped, "\n"))
        end
    end)
}
