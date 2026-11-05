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
		"moon_gate": {"name": "달빛 솟을문", "theme": "gate", "width": 1792, "platforms": [[256,576,224],[624,416,224],[1024,464,256],[1408,576,160]], "gaps": []},
		"collapsed_house": {"name": "무너진 안채", "theme": "courtyard", "width": 1792, "platforms": [[288,576,256],[672,384,224],[1056,480,256],[1440,576,160]], "gaps": [[896,96]]},
		"servants_quarters": {"name": "버려진 행랑", "theme": "hall", "width": 1536, "platforms": [[224,576,256],[592,416,256],[992,480,256]], "gaps": []},
		"black_kitchen": {"name": "검은 부엌", "theme": "store", "width": 1792, "platforms": [[320,576,192],[640,416,256],[1056,512,224],[1408,480,192]], "gaps": [[864,96]]},
		"granary": {"name": "빈 곡간", "theme": "store", "width": 1536, "platforms": [[256,576,224],[608,416,288],[1056,576,192]], "gaps": []},
		"dry_pond": {"name": "메마른 연못", "theme": "well", "width": 1792, "platforms": [[288,576,224],[640,400,192],[992,480,224],[1376,576,192]], "gaps": [[832,128]]},
		"bamboo_path": {"name": "달 없는 대숲", "theme": "forest", "width": 1792, "platforms": [[256,576,192],[576,416,224],[960,480,224],[1344,512,224]], "gaps": [[800,96]]},
		"rotten_bridge": {"name": "썩은 나무다리", "theme": "gallery", "width": 1792, "platforms": [[224,576,256],[608,352,224],[992,448,256],[1408,544,160]], "gaps": [[512,96],[1280,96]]},
		"ritual_yard": {"name": "금줄 제단", "theme": "shrine", "width": 1536, "platforms": [[256,576,224],[608,384,320],[1088,480,192]], "gaps": []},
		"grave_yard": {"name": "주인 없는 묘뜰", "theme": "forest", "width": 1792, "platforms": [[288,576,224],[672,448,224],[1056,448,224],[1408,576,160]], "gaps": [[896,96]]},
		"paper_corridor": {"name": "찢긴 문창살 복도", "theme": "gallery", "width": 1536, "platforms": [[224,576,256],[608,352,256],[1024,448,256]], "gaps": []},
		"sanctum": {"name": "봉인의 마당", "theme": "sanctum", "width": 1792, "platforms": [[352,576,192],[704,480,288],[1280,576,192]], "gaps": []}
	}
