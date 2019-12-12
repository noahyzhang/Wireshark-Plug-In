local version_str = string.match(_VERSION, "%d+[.]%d*")
local version_num = version_str and tonumber(version_str) or 5.1
local bit = (version_num >= 5.2) and require("bit32") or require("bit")

-- create a new dissector to decode rtp private payload

local NAME           = "OPUS"
local PORT           = 5004
local RTP_PROTO_TYPE = 97


local opus            = Proto(NAME, "OPUS Protocol")

-- create fields of opus

fields_M             = ProtoField.uint8 (NAME .. ".M", "M", base.HEX,Payload_type,0x80)
fields_pt            = ProtoField.uint8 (NAME .. ".PT", "PT", base.DEC,Payload_type,0x7F)
fields_seqno         = ProtoField.uint16(NAME .. ".seqno", "Sequence number")
fields_payload       = ProtoField.bytes(NAME .. ".payload", "OPUS Payload")
fields_fecPayload    = ProtoField.bytes(NAME .. ".fecPayload", "FEC Payload")


opus.fields           = { fields_M, fields_pt, fields_seqno, fields_payload,fields_fecPayload }

local RTP_dis        = Dissector.get("rtp")
--local H264_dis       = Dissector.get("h264")
--local Data_dis       = Dissector.get("data")

-- dissect packet
function opus.dissector(tvb, pinfo, tree)
	length = tvb:len()
	if length == 0 then return end
	
    -- decode private header
    local subtree = tree:add(opus, tvb(0,3))
	
	subtree:add(fields_M, tvb(0,1))
	
	subtree:add(fields_pt, tvb(0,1))
	
    subtree:add(fields_seqno, tvb(1,2))

    -- show protocol name in protocol column
    pinfo.cols.protocol = opus.name
   	
	local fec_id = tvb(0,1):uint()
	local fec_type = bit.band(fec_id,0x7F)
	if fec_type == 101 then 
		tree:add(fields_fecPayload,tvb(3))	
	else 
		tree:add(fields_payload,tvb(3))
		--H264_dis:call(tvb(3):tvb(), pinfo, tree)
	end 
	
	--[[
	local proto_id = tvb(3,1):uint()
	local proto_type = bit.band(proto_id,0x1F)
	if proto_type >= 1 and proto_type <= 23 then -- one nual
		H264_dis:call(tvb(3,1):tvb(),pinfo,tree)
		tree:add(fileds_h264bytes,tvb(3))	
	elseif proto_type >= 24 and proto_type <= 27 then  -- STAP-A sps/pps
		H264_dis:call(tvb(3,1):tvb(),pinfo,tree)
		tree:add(fileds_h264bytes,tvb(3))
	elseif proto_type == 28 then -- FU-A
		H264_dis:call(tvb(3,2):tvb(),pinfo,tree)
		tree:add(fields_h264bytes,tvb(3))
	else
		H264_dis:call(tvb(3):tvb(), pinfo, tree)
	end
	]]--
    -- decode h264 data
	--local len = (tvb:len()-3)-1
    --H264_dis:call(tvb(3):tvb(), pinfo, tree)
	--H264_dis:call(tvb(3,2):tvb(), pinfo, tree)
    --tree:add(fields_h264bytes,tvb(3))
end


--decode first layer  as rtp
local udp_dissector_table = DissectorTable.get("udp.port")
udp_dissector_table:set(PORT,RTP_dis)

-- register this dissector
-- DissectorTable.get("rtp.pt"):add(PORT, opus)
--decode private protocol layer  3-bytes private datas + standard h264
local rtp_dissector_table = DissectorTable.get("rtp.pt")
rtp_dissector_table:set(RTP_PROTO_TYPE,opus)




