extends RefCounted

# Tile coordinates are authored, not unconstrained random geometry.
# Entry/exit share a floor height; each room is wider/taller than one viewport.
static func templates() -> Dictionary:
	return {
		"gate": {"name": "무너진 대문", "theme": "gate", "width": 1536, "platforms": [[288,576,192],[608,464,224],[992,560,192]], "gaps": []},
		"courtyard": {"name": "흉가 앞마당", "theme": "courtyard", "width": 1792, "platforms": [[320,576,224],[704,448,256],[1120,576,224]], "gaps": []},
		"well": {"name": "마른 우물터", "theme": "well", "width": 1536, "platforms": [[288,576,192],[608,448,256],[1056,576,192]], "gaps": [[704,128]]},
		"hall": {"name": "빈 행랑채", "theme": "hall", "width": 1792, "platforms": [[256,576,256],[608,448,320],[1056,448,320],[1440,576,192]], "gaps": []},
		"gallery": {"name": "끊어진 회랑", "theme": "gallery", "width": 1792, "platforms": [[288,576,256],[672,448,256],[1088,448,256],[1440,576,160]], "gaps": [[608,96],[992,128]]},
		"forest": {"name": "결계 숲길", "theme": "forest", "width": 1792, "platforms": [[320,576,224],[704,448,192],[1088,576,224]], "gaps": [[864,96]]},
		"store": {"name": "봉인된 창고", "theme": "store", "width": 1536, "platforms": [[288,576,256],[672,448,224],[1056,576,192]], "gaps": []},
		"shrine": {"name": "오래된 신당", "theme": "shrine", "width": 1536, "platforms": [[320,576,224],[656,448,224],[1056,576,192]], "gaps": []},
		"sanctum": {"name": "봉인의 마당", "theme": "sanctum", "width": 1792, "platforms": [[352,576,192],[704,480,288],[1280,576,192]], "gaps": []}
	}
