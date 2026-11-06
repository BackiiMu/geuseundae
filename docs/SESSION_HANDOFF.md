# 새 PC·새 세션 작업 인계 · 2026-11-06

## 저장소와 시작점

- 저장소: `https://github.com/BackiiMu/geuseundae.git`, 브랜치 `main`.
- 실제 게임은 Godot 4.7.2의 `godot/project.godot`, 시작 장면은 `godot/scenes/village.tscn`이다.
- 루트 HTML은 과거 시안이다. 현재 구현 판단은 `godot/scripts`와 `docs/CURRENT_STATUS.md`를 따른다.
- 새 PC에서 받은 뒤 Godot 이미지 import가 끝날 때까지 기다린다.
- 기본 창은 640×360이다. 사용자가 요청하기 전에는 크게 띄우지 말고, 검수 창은 기존 위치나 화면 아래쪽에 둔다.

## 현재 게임 흐름

- 시작·사망 귀환 시 검은 인간형으로 소환된다. 심장이 없으면 런을 시작할 수 없다.
- 손각시: HP 60, 기본 무기 `손각시의 손`. Q는 화면 내 적에게 머리카락을 뻗어 앞으로 끌어오며 쿨타임 30초다. 마법진·원형 표시는 사용하지 않는다.
- 몽달귀신: HP 90, `몽달의 손톱`, Q 없음, 대시 충전 총 3회.
- 창귀: HP 70, `범의 발톱`, Q `창귀원혼`(맵 전체 적 4초 정지, 30초). 장산범 처치 후 해금.
- 몽달·창귀 8×4 시트의 프레임별 몸 크기·중심·발 위치 차이는 `actor_sprite.gd`에서 정규화했다. 대기와 이동도 같은 보이는 높이를 유지한다.
- 점프키는 착지 상태의 첫 입력만 점프다. 점프 후 착지 전 재입력은 대시키와 동일하게 현재 공격 조준 방향으로 8방향 대시한다. Shift, 이동키 연타, 공중 점프키 대시는 모두 공격 방향을 사용한다. 모바일도 별도 점프 버튼의 첫 입력은 점프, 공중 재입력은 오른쪽 공격 스틱 방향 대시다.

## 챕터 상태

- 1챕터: 시드 기반 방, 방 포탈 1~4개, 우물 지도 이동, 평화방·도깨비상인, 퇴마단 선봉대장 보스가 동작한다.
- 전투, 장비/가방, 영혼조각 자동 획득, 방 보상, 확인 후 장비 파기가 연결되어 있다.
- 2챕터는 안개 낀 산이다. 창귀 잔혼·미혹불·호식총 원귀·산호랑이와 장산범 그림자 정예가 등장한다.
- 장산범 보스는 플레이어 복제형(HP 260, 기본 할퀴기) → 그림자(HP 450) → 흰 몸·붉은 얼굴 장산범(HP 850)의 독립 체력 3페이즈다.
- 각 페이즈 처치 시 전투가 멈추고 Pixelfx 날씨 안개가 보스를 완전히 가린 뒤 다음 모습으로 전환한다.
- 최종 장산범은 크게 확대했고 발 위치와 충돌 범위도 외형에 맞췄다. 최종 처치 시 장산범 장비 하나와 장산범 세트·창귀 심장 해금을 처리한다.
- 상세 기준은 `docs/chapter-two-fog-mountain.md`, 검수 캡처는 `docs/reviews/chapter2/`에 있다.

## 주요 코드

- `godot/scripts/random_run.gd`: 마을·런·방 이동·층 흐름.
- `godot/scripts/combat_director.gd`: 전투, 보상, 인벤토리, 심장 스킬.
- `godot/scripts/combat_enemy.gd`: 적과 장산범 3페이즈.
- `godot/scripts/actor_sprite.gd`: 캐릭터 시트와 신규 심장 캐릭터 크기 보정.
- `godot/scripts/heart_db.gd`, `heart_npc.gd`: 심장 데이터와 NPC.
- `godot/scripts/equipment_db.gd`, `equipment_runtime.gd`: 장비 데이터와 효과.
- `godot/scripts/pixel_vfx.gd`: 전투 이펙트.
- `vendor/pixelfx/`: Pixelfx 원본과 프로젝트 전용 효과.
- `docs/HEART_CHARACTERS.md`: 심장 캐릭터 기준.
- `geuseundae_equipment.md`: 장비 원안. 의도적으로 이상한 두억시니 장비 이름을 임시 이름으로 고치지 않는다.

## 핵심 검수

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/heart_identity_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/chapter_two_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/combat_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/vfx_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/random_run_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/dash_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/mobile_controls_test.gd
```

2026-11-06 기준 핵심 검사와 대시 검사가 통과했다. macOS 헤드리스 실행의 시스템 인증서 조회 경고는 게임 테스트 실패가 아니다. `combat_live_test.gd`는 과거 근접 적 처치 타이밍에 따라 간헐 실패한 기록이 있어 별도 재현이 필요하다.

## iOS/Xcode

- 프리셋: `iOS Xcode`. 인증서와 `DEVELOPMENT_TEAM`은 비워 두고 사용자가 Xcode에서 선택한다.
- 2026-11-06 내보내기와 ZIP 무결성 검사를 통과했다.
- 로컬 산출물은 `builds/ios/Geuseundae-Xcode.zip`(약 147MB)이다. `builds/`는 Git 제외이므로 다른 Mac에서는 다시 내보낸다.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --export-debug "iOS Xcode" ../builds/ios/Geuseundae-Xcode.zip
```

- 임시 앱 아이콘 자동 리사이즈와 App Store 1024 아이콘 투명도 경고가 남아 있다.

## 다음 우선순위

1. 몽달·창귀 크기 보정 후 이동 애니메이션의 폭 변화와 잔상을 실제 플레이로 확인한다.
2. 2챕터 전체 동선을 플레이해 장산범 3페이즈 공격 밸런스와 큰 충돌 범위를 조정한다.
3. 변신 안개 속도·밝기를 실제 전투 배경에서 최종 조정한다.
4. 도깨비상인·상점 UI를 최신 도트 인벤토리 스타일로 통일한다.
5. 불투명 App Store 아이콘 제작과 iPhone 실기기 서명·설치 검증.

## 유지할 디자인 규칙

- 두억시니 무기는 검은 그림자 주먹이다.
- 손각시의 손과 손각시 머리카락은 별도 아이템이며 무기가 없으면 공격하지 않는다.
- 창귀는 갓 없는 일반 농노다. 산발, 절단된 팔·다리의 백골, 배의 호랑이 발톱 상처를 유지한다.
- 장비와 몬스터 이펙트는 제공된 원본과 Pixelfx 리소스를 우선 사용한다.
- 도깨비상인은 영혼조각을 아이템으로 바꾼다. 마을은 1·2단계 4개, 층 상점은 고층일수록 상위 등급 확률이 오른다.
- 빌드, 인증서, 프로비저닝 파일, 개인 개발팀 설정은 Git에 넣지 않는다.
