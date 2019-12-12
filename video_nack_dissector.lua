local version_str = string.match(_VERSION, "%d+[.]%d*")
local version_num = version_str and tonumber(version_str) or 5.1
local bit = (version_num >= 5.2) and require("bit32") or require("bit")

-- create a new dissector to decode rtp private payload

local NAME            = "NACK"
local PORT            = 5004
local RTP_PROTO_TYPE = 107  --video



local video_nack            = Proto(NAME, "NACK Protocol")

-- create fields of video_nack
fileds_PristinePT     = ProtoField.uint16(NAME .. ".RedSequenceNumber","Red Sequence number")
fields_M             = ProtoField.uint8 (NAME .. ".M", "M", base.HEX,Payload_type,0x80)
fields_pt            = ProtoField.uint8 (NAME .. ".PT", "PT", base.DEC,Payload_type,0x7F)
fields_seqno         = ProtoField.uint16(NAME .. ".seqno", "Sequence number")
fields_h264bytes     = ProtoField.bytes(NAME .. ".bytes", "H264Data")
fields_nack          = ProtoField.bytes(NAME .. ".payload", "nack Payload")

video_nack.fields           = { fileds_PristinePT, fields_M, fields_pt, fields_seqno, fields_h264bytes, fields_nack }

local RTP_dis        = Dissector.get("rtp")
local H264_dis       = Dissector.get("h264")
local Data_dis       = Dissector.get("data")

-- dissect packet
function video_nack.dissector(tvb, pinfo, tree)
	length = tvb:len()
	if length == 0 then return end
	
    -- decode private header
    local subtree = tree:add(video_nack, tvb(0,5))
	
	subtree:add(fileds_PristinePT,tvb(0,2))
	subtree:add(fields_M, tvb(2,1))
	subtree:add(fields_pt, tvb(2,1))
	
    subtree:add(fields_seqno, tvb(3,2))

    -- show protocol name in protocol column
    pinfo.cols.protocol = video_nack.name
   	
	tree:add(fields_nack,tvb(3))
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
    --H264_dis:call(tvb(5):tvb(), pinfo, tree)
	--H264_dis:call(tvb(3,2):tvb(), pinfo, tree)
    --tree:add(fields_h264bytes,tvb(3))
end


--decode first layer  as rtp
local udp_dissector_table = DissectorTable.get("udp.port")
udp_dissector_table:add(PORT,RTP_dis)

-- register this dissector
-- DissectorTable.get("rtp.pt"):add(PORT, video_nack)
--decode private protocol layer  3-bytes private datas + standard h264
local rtp_dissector_table = DissectorTable.get("rtp.pt")
rtp_dissector_table:add(RTP_PROTO_TYPE,video_nack)





