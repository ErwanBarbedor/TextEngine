txe.last_error = nil
txe.traceback = {}

local function token_info (token)
    -- Return:
    -- Name of the file containing the token
    -- The and number of the content of the line containing the token, 
    -- The begin and end position of the token.
    
    -- print(debug.traceback())

    local file, token_noline, token_line, code, beginpos, endpos

    -- Find all informations about the token
    if token.kind == "opt_block" or token.kind == "block" then
        file = token.first.file
        token_noline = token.first.line
        code = token.first.code
        beginpos = token.first.pos

        if token.last.line == token_noline then
            endpos = token.last.pos+1
        else
            endpos = beginpos+1
        end
    elseif token.kind == "block_text" then
        file = token[1].file
        token_noline = token[1].line
        code = token[1].code
        beginpos = token[1].pos

        endpos = token[#token].pos + #token[#token].value
    else
        file = token.file
        token_noline = token.line
        code = token.code
        beginpos = token.pos
        endpos = token.pos+#token.value
    end

    -- Retrieve the line in the source code
    local noline = 1
    for line in (code.."\n"):gmatch("(.-)\n") do
        if noline == token_noline then
            token_line = line
            break
        end
        noline = noline + 1
    end

    return file, token_noline, token_line, beginpos, endpos
end

function txe.error (token, message)
    -- Enhance errors messages by adding
    -- information about the token that
    -- caused it.

    -- If it is already an error, throw it.
    if txe.last_error then
        error(txe.last_error)
    end

    local file, noline, line, beginpos, endpos = token_info (token)
    local err = "File '" .. file .."', line " .. noline .. " : " .. message .. "\n"
    err = err .. "\t"..line .. "\n"

    -- Add '^^^' under the fautive token
    err = err .. '\t' .. (" "):rep(beginpos) .. ("^"):rep(endpos - beginpos)

    -- Add traceback
    if #txe.traceback > 0 then
        err = err .. "\nTraceback :"
    end

    local last_line_info
    local same_line_count = 0
    for i=#txe.traceback, 1, -1 do
        file, noline, line, beginpos, endpos = token_info (txe.traceback[i])
        local line_info = "\n\tFile '" .. file .."', line " .. noline .. " : "
        local indicator = (" "):rep(#line_info + beginpos - 2) .. ("^"):rep(endpos - beginpos)

        -- In some case, like stack overflow, we have 1000 times the same line
        -- So print up to two time the line, them count and print "same line X times"
        if txe.traceback[i] == txe.traceback[i+1] then
            same_line_count = same_line_count + 1
        elseif same_line_count > 1 then
            err = err .. "\n\t(same line again " .. (same_line_count-1) .. " times)"
            same_line_count = 0
        end

        if same_line_count < 2 then
            last_line_info = line_info
            
            err = err .. line_info .. line .. "\n"
            err = err .. '\t' .. indicator
        end
    end

    if same_line_count > 0 then
        err = err .. "\n\t(same line again " .. (same_line_count-1) .. " times)"
    end

    -- Save the error
    txe.last_error = err

    -- And throw it
    error(err, -1)
end