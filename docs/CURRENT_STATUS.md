# 새 PC·새 세션 인계 · 2026-11-05

## 바로 시작하기

1. `git clone https://github.com/BackiiMu/geuseundae.git`
2. Godot 4.7.2에서 `godot/project.godot`을 연다.
3. 시작 장면은 `godot/scenes/village.tscn`이다.
4. 기본 창은 640×360이며 사용자가 요청하기 전에는 크게 띄우지 않는다.
5. 첫 실행 전 Godot이 이미지 import를 마칠 때까지 기다린다.

헤드리스 확인 예시:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/inventory_ui_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/merchant_test.gd
```

## 현재 핵심 구현

- 시드 기반 방 연결, 방 포탈 1~4개, 우물 지도 이동, 층별 평화구역과 도깨비상인.
- 전투, 장비/가방, 영혼조각 자동 획득, 방 보상, 1챕터 보스와 2챕터 안개 산·장산범 흐름.
- PC 조작, 마우스 조준과 방향키 8방향 공격, 모바일 듀얼 스틱/점프 버튼.
- 손각시 심장 HP60. Q는 화면 안 적을 머리카락으로 앞으로 끌며 쿨타임 30초.
- 장비 파기는 확인 후 영구 제거. 장비와 드롭은 제공된 아트 및 pixelfx 리소스를 우선 사용한다.
- 인벤토리는 768×432 논리 화면에서 비율을 유지하고, 가변 악세사리 레일과 6×5 가방을 사용한다.
- 인벤토리 UI는 한 장짜리 배경이 아니라 9패치 패널·도트 슬롯·버튼 부품으로 조립한다.

주요 코드:

- `godot/scripts/random_run.gd`: 마을, 런, 방 이동, 상인 배치.
- `godot/scripts/combat_director.gd`: 전투와 인벤토리.
- `godot/scripts/equipment_db.gd`, `equipment_runtime.gd`: 장비 데이터와 동작.
- `godot/scripts/combat_enemy.gd`: 적과 보스.
- `godot/scripts/merchant.gd`, `merchant_stock.gd`: 도깨비상인과 재고.
- `godot/scripts/inventory_modular_skin.gd`: 조각식 인벤토리 외형.
- `godot/scripts/actor_sprite.gd`: 캐릭터 시트 재생.
- `godot/scripts/pixel_vfx.gd`: 전투 이펙트.

## 2026-11-05 캐릭터 아트

`godot/assets/actors/concepts/`에 원본과 게임 크기 기준 이미지를 함께 둔다.

- `mongdal-ghost-v1.png`: 혼례를 못 치른 몽달귀신. 미완성 혼례복, 목각 기러기, 붉은 혼례 매듭.
- `changwi-peasant-v2.png`: 일반 농노 창귀. 갓 없음, 산발, 삼베옷, 한쪽 팔과 반대쪽 다리 결손 및 백골, 배의 호랑이 발톱 상처.
- `dokkaebi-villager-v1.png`: 빗자루와 장작바구니를 든 마을 도깨비.
- `dokkaebi-merchant-v1.png`: 보따리와 금동전 더미 사이에 한량처럼 앉아 곰방대를 든 상인.
- `*-game-*.png`: 게임 배치용 축소본. 최종 애니메이션 시트가 아니라 기준 포즈다.

도깨비상인 축소본은 `merchant.gd`에 연결되어 기존 임시 도형을 교체했다. 몽달귀신·창귀는 심장 캐릭터 선택과 8×4 애니메이션 시트 1차 적용까지 연결했으며, 일반 도깨비의 역할은 아직 미정이다.

## 다음 작업 우선순위

1. 몽달귀신·창귀는 심장 캐릭터로 확정했다. 세부 기준은 `docs/HEART_CHARACTERS.md`를 따른다.
2. 몽달귀신·창귀 8×4 시트의 실기기 동작 검수와 프레임별 잔상·자세 다듬기.
3. 도깨비상인의 게임 내 크기·바닥 위치·상호작용 표지 실기기 검수.
4. 상점 UI를 최신 인벤토리 도트 UI 부품과 같은 스타일로 재설계.
5. App Store 제출 전 불투명 1024 아이콘 제작. 현재 Xcode export는 임시 아이콘 자동 리사이즈 경고가 있다.

## 검수 상태

- 2층부터 안개 낀 산 배경·화면 안개·산악 방 이름을 사용한다. 창귀 잔혼·미혹불·호식총 원귀·산호랑이와 장산범의 그림자 정예가 등장한다. 장산범 보스는 플레이어 복제형(HP 260) → 그림자(HP 450) → 백색 장산범(HP 850)의 독립 체력 3페이즈이며, 페이즈 처치마다 전투 정지·안개 은폐·외형 전환을 거친다. `chapter_two_test.gd`와 실제 렌더 캡처를 통과했다.
- 선봉대장과 장산범 보상을 분리했다. 창귀 심장과 장산범 세트는 실제 장산범 처치 후 해금된다.
- 몽달귀신은 기본 해금 심장(HP 90, 몽달의 손톱, 대시 총 3회, Q 없음), 창귀는 장산범 처치 해금 심장(HP 70, 범의 발톱, 맵 전체 적 4초 정지 `창귀원혼`)으로 연결했다. 창귀원혼은 Pixelfx PNG+JSON 시트를 사용하며 2026-11-06 자동 회귀 테스트를 통과했다.
- 몽달귀신·창귀 캐릭터 시트는 각각 `assets/actors/source/mongdal-v1.png`, `assets/actors/source/changgui-v1.png`에 1536×1024(8×4) 규격으로 1차 적용했다. 이번 시트 적용 후에는 요청에 따라 게임을 실행하지 않고 파일 규격과 자동 연결 경로만 확인했다.
- `inventory_ui_test.gd`: 화면비 유지, 가변 악세사리 2/4/6칸, 가방 30칸, 심장 표시, 선택 Pixelfx 통과.
- `merchant_test.gd`: 200개 시드, 마을 4상품, 층별 평화방 1개, 재고 재현성, 등급 확률, 구매·품절 유지 통과.
- UI/상인 변경 후 위 두 테스트를 다시 통과했다.
- 전체 테스트 중 과거 `combat_live_test.gd`가 간헐적으로 근접 적 처치 타이밍에서 실패한 기록이 있다. 별도 재현/수정이 필요하다.

## 내보내기

- iOS 프리셋: `iOS Xcode`, 인증서와 실제 Team ID는 지정하지 않는다.
- 로컬 최신 산출물: `builds/ios/Geuseundae-Xcode.zip` (Git 제외). Xcode에서 개발팀과 인증서를 직접 선택한다.
- iOS 내보내기는 성공했으나 임시 앱 아이콘 크기 자동 조절과 App Store 아이콘 투명도 경고가 남아 있다.
- Android/Windows/macOS 프리셋은 `godot/export_presets.cfg`에 있다. 빌드 산출물과 인증서는 Git에 넣지 않는다.

## 중요한 디자인 규칙

- 장비 원안은 루트 `geuseundae_equipment.md`. 의도적으로 이상하게 지은 두억시니 장비 이름을 임시 이름으로 고치지 않는다.
- 두억시니 무기는 검은 그림자 주먹이다.
- 손각시의 손과 손각시 머리카락은 별도 아이템이다. 무기가 없으면 공격하지 않는다.
- 도깨비상인은 영혼조각을 아이템으로 바꿔 준다. 마을은 1·2단계 4개, 층 상점은 높은 층일수록 상위 등급 확률이 오른다.
- 창귀는 높은 신분의 사냥꾼이 아니라 일반 농노다. 갓을 씌우지 않는다.
- 루트 HTML은 과거 시안이며 실제 게임 기준은 Godot이다.

## 외부 코드와 라이선스

- pixelfx 원본: https://github.com/patch-gg/pixelfx.git
- 기반 커밋: `a84159688af3ca37a4be05a0d422b94451b2e24e`
- 생성기: `vendor/pixelfx/tools/export-geuseundae.mjs`
- 라이선스와 출처는 루트 `THIRD_PARTY.md`를 유지한다.
