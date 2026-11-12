# 최신 작업 인계 · 2026-11-06

이 문서가 유일한 진행 상황·인계 문서다. 현재 구현 판단은 `godot/scripts`와 `docs/equipment-implementation.md`를 따른다.

## 바로 시작하기

1. 저장소: `https://github.com/BackiiMu/geuseundae.git`, 브랜치 `main`.
2. Godot 4.7.2에서 `godot/project.godot`을 연다. 시작 장면은 `godot/scenes/intro_screen.tscn`(약 24초 인트로, 우상단 `건너뛰기`·Esc)이며 끝나면 `title_screen.tscn`으로 이어지고 `게임 시작`을 누르면 마을로 들어간다.
3. 첫 실행 전 Godot이 이미지 import를 마칠 때까지 기다린다.
4. 루트 HTML은 과거 시안이다.
5. 기본 창은 640×360이다. 사용자가 요청하기 전에는 키우거나 옮기지 않고, 검수 창은 기존 위치나 화면 아래쪽에 둔다.

## 현재 게임 흐름

- 시작·사망 귀환 시 검은 인간형으로 소환된다. 심장이 없으면 런을 시작할 수 없다.
- 손각시: HP 60, 기본 무기 `손각시의 손`. Q는 화면 내 적에게 머리카락을 뻗어 앞으로 끌어오며 쿨타임 30초다. 마법진·원형 표시는 쓰지 않는다.
- 몽달귀신: 기본 해금, HP 90, `몽달의 손톱`, Q 없음, 대시 충전 총 3회.
- 창귀: 장산범 처치 후 해금, HP 70, `범의 발톱`, Q `창귀원혼`(맵 전체 적 4초 정지, 30초). 창귀원혼은 Pixelfx PNG+JSON 시트를 쓴다.
- 몽달·창귀 시트는 `assets/actors/source/mongdal-v1.png`, `changgui-v1.png`(1536×1024, 8×4). 프레임별 몸 크기·중심·발 위치는 `actor_sprite.gd`에서 정규화해 대기와 이동이 같은 보이는 높이를 유지한다.

### 조작

- PC: 이동 A/D, 점프 Space, 대시 Shift, 공격 J/마우스 왼쪽(방향키 8방향 조준), 심장 Q, 주무기/보조무기 스킬 F/G, 상호작용 E, 가방 Tab/I.
- 대시 방향
  - **PC**: Shift, 방향키 연타, 점프 후 착지 전 Space 재입력 모두 공격 조준 방향(8방향). 조준이 없으면 바라보는 방향.
  - **모바일**: 대시 버튼과 공중 점프 재입력 모두 왼쪽 이동 스틱의 자유 각도를 그대로 따른다. 스틱을 놓고 있으면 바라보는 방향. 구현은 `player.gd`의 `mobile_dash_direction()`과 `mobile_controls.gd`의 `move_vector`이며 `mobile_controls_test.gd`에서 임의 아날로그 각도와 중립 방향을 검사한다. 실기기·`--touch` 확인은 아직 하지 않았다.
- 점프키는 착지 상태의 첫 입력만 점프다. 모바일도 별도 점프 버튼의 첫 입력은 점프이며, 오른쪽 스틱은 공격 조준만 맡는다.
- 개발용: 장비 실험실 F6, 무기 변경 [ / ], 표적 초기화 T, 두억시니 세트 P, 정지 F9, 표적 AI Y, 재시작 R, 다음 시드 N.
- F6는 캐릭터·장비 통합 시험장이다. `[ ]`로 무기뿐 아니라 패시브 장비까지 전체 43종을 즉시 장착하고, `, .`로 손각시·몽달귀신·창귀를 해금 상태와 무관하게 전환한다. Tab 가방에도 전체 장비가 있으며 시험 종료 시 원래 장비·캐릭터·최대 HP·진행 상태를 복원한다.
- F7은 전체 해금 실전 런이다. 모바일에서는 타이틀의 `전체 장비 테스트`로 진입한다. 별도 시험방이 아니라 정상 시드 방 배치·상점·층 이동·보스 흐름을 그대로 사용하며, 시작 가방에 전 장비 43종과 영혼조각 9999개를 지급한다. 진행 중 PC는 `, .`, 모바일은 가방의 심장 칸 터치로 세 심장 캐릭터를 자유롭게 전환한다.

## 챕터 상태

- 1챕터: 시드 기반 방, 방 포탈 1~4개, 우물 지도 이동, 층별 평화방과 도깨비상인, 퇴마단 선봉대장 보스.
- 전투, 장비/가방, 영혼조각 자동 획득, 방 보상, 확인 후 장비 파기(영구 제거)가 연결되어 있다. 저장 기능은 없다.
- 2챕터는 안개 낀 산이다. 창귀 잔혼·미혹불·호식총 원귀·산호랑이와 장산범 그림자 정예가 등장한다.
- 장산범 보스는 플레이어 복제형(HP 260, 기본 할퀴기) → 그림자(HP 450) → 흰 몸·붉은 얼굴 장산범(HP 850)의 독립 체력 3페이즈다.
- 각 페이즈 처치 시 전투가 멈추고 Pixelfx 날씨 안개가 보스를 완전히 가린 뒤 다음 모습으로 전환한다. 최종 장산범은 크게 확대했고 발 위치와 충돌 범위도 외형에 맞췄다.
- 선봉대장과 장산범 보상은 분리했다. 최종 처치 시 장산범 장비 하나와 장산범 세트·창귀 심장이 해금된다.
- 상세 기준은 `docs/chapter-two-fog-mountain.md`, 검수 캡처는 `docs/reviews/chapter2/`.
- 3챕터는 **퇴마단 주둔지**다. 3층 진입 시 전용 주둔지 배경·방 이름을 사용하고 2챕터 안개는 제거된다.
- 일반 적은 퇴마 창수(도약 내려찍기), 퇴마 궁수(위에서 떨어지는 3연속 화살), 방울 술사(바닥 금줄 봉인), 사냥매(HP 32, 대각선 급강하) 4종이다. 1챕터의 전방 휘두르기·직선 투사체와 회피 방향이 겹치지 않게 구성했다.
- 3층 마지막 방은 `쇄혼대감` 보스전이다(HP 760). 검붉은 군무당 복식·철제 반가면·쇠사슬·봉인말뚝과, 억눌린 귀신들이 새어 나오는 등짐형 봉인목을 사용한다. 일반 공격 사이 종료 기준 10~15초 무작위 간격으로 포획·삼중 봉인을 사용하고, HP 30% 이하에서는 심장 적출이 20% 확률로 추가된다. 같은 패턴은 연속으로 나오지 않는다.
- 모든 특수 패턴 시작에는 이미지 기반 16프레임 원혼 강제 인출 모션을 공통 재생한다. 봉인목에서 괴로워하는 세 귀신이 올라와 저항하다가 쇠사슬 쪽으로 끌려가며, 이후 포획·삼중 봉인·심장 적출 전용 후속 모션으로 이어진다. 대기는 애니메이션 없이 기준 포즈 한 장으로 고정하고 이동·피격·그로기·말뚝·사슬·사망은 전용 이미지 시트를 사용한다.
- 포획은 2초 제한의 4연타 구슬을 3~5회 처리한다. 성공 시 보스 최대 HP 5% 피해와 2초 그로기, 실패 시 플레이어 15 피해와 1초 그로기다. 삼중 봉인은 말뚝당 최대 HP 5 감소(최소 30), 심장 봉인, 대시 최대 충전 1 감소를 적용하며 말뚝 파괴마다 HP 5를 복구하고 전부 파괴하면 보스가 3초 그로기다. 심장 적출은 5초 부적 낙하 회피이며 무피격 시 2초 그로기, 종료 후 외형·HP 제한·심장 기능을 복구한다.
- 구현 기준은 `docs/chapter-three-exorcist-garrison.md`, 검수 캡처는 `docs/reviews/chapter3/`, 자동 검사는 `chapter_three_test.gd`와 `chapter_three_live_test.gd`다.

## UI

- 인벤토리는 768×432 논리 화면에서 비율을 유지한다. 가변 악세사리 레일(2/4/6칸)과 6×5 가방을 쓰고, 한 장짜리 배경이 아니라 9패치 패널·도트 슬롯·버튼 부품으로 조립한다(`inventory_modular_skin.gd`).
- 인벤토리 배치는 `godot/assets/ui/layouts/inventory-layout.json`을 실제로 읽는다. 화면 비율에 따라 landscape·compact·portrait 프로필을 고르고, 장비·가방·상세 영역 좌표와 가방 열/간격을 JSON에서 가져온다(`inventory_layout.gd`).
- 시작 장면은 `title_screen.tscn`이다. 버튼 없는 흉가 배경 위에 실제 Godot `게임 시작`·`설정` 버튼을 배치하며, 게임 시작은 마을로 연결된다.
- 게임 HUD는 이미지 HP바, 엽전형 대시 충전, 가방 수량과 닫힘→반열림→열림 애니메이션, 설정 버튼을 쓴다(`game_hud.gd`). 설정에는 도트 음량 슬라이더와 전체 화면 토글이 있다.
- 도깨비상인은 영혼조각을 아이템으로 바꿔 준다. 마을은 1·2단계 4개, 층 상점은 높은 층일수록 상위 등급 확률이 오른다(`merchant.gd`, `merchant_stock.gd`).

## 시작·변신 소환

- 시작·부활·심장 변신은 `assets/vfx/summon/shadow-rise.png`와 JSON(170×112, 175프레임, 30fps, 피벗 85×92)을 사용한다. 원본 약 5.8초를 5배속으로 재생해 약 1.2초에 끝나며 바닥 피벗을 유지한다.
- 시각 검수 캡처는 `docs/reviews/ui/`에 있다. `ui_visual_review.gd`가 인트로·그림자 소환·마을 HUD·JSON 인벤토리·설정을 실제 렌더러로 저장한다.

## 범의 송곳니 F 스킬 · 푸른 호랑이

- F 스킬(호랑이 혼령 관통)의 그림을 제공 이미지 `docs/mockups/equipment/tiger-fang/tiger-fang-spirit-projectile-pixel-v2.png`에서 만든 푸른 호랑이 머리로 교체했다. 배경·광을 뺀 80×51 도트에 꼬리 물결과 머리 흔들림을 넣은 12프레임 반복 시트 `godot/assets/vfx/tiger-spirit.png`(+`.json`, `manifest.json`의 `tiger-spirit`)이며 `pixel_vfx.gd`가 3배로 그린다(이전 시안 2배의 1.5배). 생성은 `docs/mockups/equipment/tiger-fang/build_sheet.py`.
- 피해 45·속도 850·수명 1.15초·관통 같은 규칙은 그대로다. 시안에 있던 충전·충격 고리·잔상·적중 베기 연출은 적용하지 않았다. `vfx_test.gd`는 시트 수 32와 `tiger-spirit`(12프레임·20fps)를 검사하도록 고쳤다.

## 장비 아이콘·드롭 연결

- 임시 초안 아이콘이던 무기 19종 중 만들어 둔 `assets/gear3/icons`·`assets/gear3/drop` 이미지가 있는 17종(몽달의 손톱, 부러진 나무기러기, 몽달의 한, 창귀의 부름, 홀린 넋, 범의 송곳니, 물귀신의 손, 우물 두레박, 여우불, 둔갑 거울, 도깨비방망이, 낡은 빗자루, 씨름 샅바, 아귀의 이빨·혀, 어둑한 그림자, 흉내 내는 목소리, 가는 휘파람, 거구귀의 입)을 `item_icon.gd`의 `GEAR3_ITEMS`와 `combat_director.gd`의 `GEAR3_DROPS`에 연결했다. 가방·상점 아이콘과 바닥 드롭 모습이 모두 바뀐다.
- 캡처: `docs/equipment-report/images/drops-gear3.png`, `inventory-equipped.png`. 새 이미지를 만들지는 않았다.

## 장산범의 앞발 범위

- 판정은 가슴 기준 앞쪽 타원이다: 앞 끝 150(`cx` 45 + `a` 105), 위아래 ±85, 중심이 가슴보다 14 위(`cy`). 머리 위부터 발 아래까지 덮고 옆으로 넓다. 가까운 적(50px 이내)은 항상 맞고 적 크기만큼 여유를 준다(`equipment_runtime.gd`의 `PAW_ARC`, `paw_strike`). DB 사거리 값도 150이다.
- 그림은 기존 `jangsan-paw` 발톱 시트(`assets/gear3/fx/`)를 늘이거나 휘지 않고 정수 3배로 키워 쓴다. 발톱이 그려지는 영역의 오른쪽 끝이 가슴 기준 앞 180(판정보다 30 앞), 세로 중심이 가슴보다 14 위가 되도록 `pixel_vfx.gd`가 배치한다. 초승달 도형 그리기는 제거했다.
- `equipment_test.gd`·`vfx_test.gd` 통과, 마을에서 실제 렌더러로 휘둘러 배치를 확인했다. 실제 적을 맞히는 체감과 피해(34)·간격(0.82초)은 확인하지 못했다. 시안은 `jangsan-paw-preview.html`.

## 주요 코드

- `godot/scripts/random_run.gd`: 마을·런·방 이동·층 흐름·상인 배치.
- `combat_director.gd`: 전투, 보상, 인벤토리, 심장 스킬.
- `combat_enemy.gd`: 적과 장산범 3페이즈.
- `actor_sprite.gd`: 캐릭터 시트 재생과 크기 보정.
- `heart_db.gd`, `heart_npc.gd`: 심장 데이터와 NPC (`docs/HEART_CHARACTERS.md`).
- `equipment_db.gd`, `equipment_runtime.gd`: 장비 데이터와 효과.
- `pixel_vfx.gd`: 전투 이펙트. `vendor/pixelfx/`는 Pixelfx 원본과 프로젝트 전용 효과.
- `player.gd`, `mobile_controls.gd`: 이동·대시·모바일 조작.

## 캐릭터 아트

`godot/assets/actors/concepts/`에 원본과 게임 크기 기준 이미지를 함께 둔다. `*-game-*.png`는 최종 애니메이션 시트가 아닌 기준 포즈다.

- `mongdal-ghost-v1.png`: 혼례를 못 치른 몽달귀신. 미완성 혼례복, 목각 기러기, 붉은 혼례 매듭.
- `changwi-peasant-v2.png`: 일반 농노 창귀.
- `dokkaebi-villager-v1.png`: 빗자루와 장작바구니를 든 마을 도깨비. 역할은 아직 미정.
- `dokkaebi-merchant-v1.png`: 보따리와 금동전 더미 사이에 앉아 곰방대를 든 상인. `merchant.gd`에 연결했다.

## 검수

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/<테스트>.gd
```

핵심: `heart_identity_test`, `chapter_two_test`, `combat_test`, `vfx_test`, `random_run_test`, `dash_test`, `mobile_controls_test`, `inventory_ui_test`, `merchant_test`.

- 2026-11-09 기준 몬스터 VFX·2챕터·전투·PC 대시·모바일 조작 자동 검사 통과. 모바일 대시는 이동 스틱의 자유 각도를 유지하며, 키보드 공격 방향만 8방향이다.
- macOS 헤드리스의 시스템 인증서 조회 경고는 테스트 실패가 아니다.
- `combat_live_test.gd`는 근접 적 처치 타이밍에서 간헐 실패한 기록이 있어 별도 재현·수정이 필요하다.

## 몬스터 공격 이펙트·짐승 스프라이트 (적용만 하고 실행은 하지 않음)

- 몬스터별 공격 이펙트를 `godot/assets/monster_vfx/`에 추가·교체하고 `combat_enemy.gd`의 `ATTACK_VFX`로 연결했다(무사·승려·창귀 잔혼·산호랑이·장산범 그림자·미혹불·호식총 원귀). 모두 반짝임·광 없는 무광이다. 승려는 기존 `monk-moktak` 시트를 먼지 충격파로 교체했다. 부적 도사는 시전·명중 이펙트를 없애 날아가는 부적(`talisman-shot`)만 남겼다(`talisman-cast`·`talisman-hit` 삭제, `monster_impact` 호출 제거).
- 산호랑이·장산범 그림자(2페이즈 보스 포함)는 192×256 칸을 가로세로 따로 줄여 납작했고 발이 떠 있었다. `actor_sprite.gd`의 `BEAST_SPRITES`로 같은 비율로 그리고 프레임별 발끝을 바닥에 맞췄다. 장산범 본체(`jangsanbeom`)는 손대지 않았다.
- **검증 안 됨:** 새 PNG의 `.import`는 헤드리스 `--import`로 만들었다. 게임·`vfx_test.gd`·`chapter_two_test.gd`는 실행하지 않았다(`vfx_test.gd`는 새 이름에 맞게 고쳤다). 호랑이 크기 `0.43`, 그림자 `0.5`는 실측 비율 기반 값이므로 화면으로 확인하고 조정한다.
- 시안과 범위 비교 페이지: 루트 `monster-attack-vfx-preview.html`, 시트 원본은 `docs/mockups/monster-attack-vfx/`.

## 1챕터 보스 공격 간격

- 퇴마단 선봉대장의 공격 사이 간격(후딜)이 너무 짧아 어렵다는 피드백으로 `combat_enemy.gd`의 보스 `recovery_duration`을 넓은 베기 0.59→0.95초, 내려베기 0.68→1.3초, 돌진 0.52→1.1초로 늘렸다. 선딜(예고)은 그대로다. 실행해서 난이도를 확인하지 않았다.

## 내보내기

모바일 내보내기·설치는 사용자가 나중에 하기로 했다. 재개 요청 전에는 실행하지 않는다.

- iOS 프리셋 `iOS Xcode`: 인증서와 `DEVELOPMENT_TEAM`은 비워 두고 사용자가 Xcode에서 지정한다. 2026-11-06 몬스터 이펙트·보스 간격 반영 후 다시 내보내고 ZIP 무결성 검사를 통과했다(App Store 아이콘 불투명 경고는 그대로).
- 로컬 산출물 `builds/ios/Geuseundae-Xcode.zip`(약 170MB)은 Git 제외라 다른 Mac에서는 다시 내보낸다.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --export-debug "iOS Xcode" ../builds/ios/Geuseundae-Xcode.zip
```

- 임시 앱 아이콘 자동 리사이즈와 App Store 1024 아이콘 투명도 경고가 남아 있다.
- Windows: `Windows Playtest` 프리셋(PCK 내장)으로 내보낸 `Geuseundae.exe`와 `README-KO.txt`를 `Geuseundae` 폴더째 `builds/windows/Geuseundae-Windows-Playtest.zip`(압축 해제 후 exe 바로 실행)에 담았다. 서명하지 않아 SmartScreen 경고가 뜰 수 있다. Windows 실기기 실행은 확인하지 않았다.
- Android/Windows/macOS 프리셋은 `godot/export_presets.cfg`에 있다. 빌드, 인증서, 프로비저닝 파일, 개인 개발팀 설정은 Git에 넣지 않는다.

## 다음 우선순위

1. 몽달·창귀 이동 애니메이션의 폭 변화와 잔상을 실제 플레이로 확인.
2. 2챕터 전체 동선을 플레이해 장산범 3페이즈 공격 밸런스와 큰 충돌 범위 조정.
3. 실제 플레이에서 쇄혼대감의 새 이동·일반공격·패턴·그로기·사망 시트 크기와 타격 타이밍을 최종 조정.
4. 변신 안개 속도·밝기를 실제 전투 배경에서 최종 조정.
5. 도깨비상인 크기·바닥 위치·상호작용 표지 실기기 검수, 상점 UI를 최신 도트 인벤토리 스타일로 통일.
6. 불투명 App Store 아이콘 제작과 iPhone 실기기 서명·설치 검증.
7. 모바일 자유 각도 대시와 공격 조준을 실기기에서 확인.

## 유지할 디자인 규칙

- 장비 원안은 루트 `geuseundae_equipment.md`. `두??니??의 XX??`, `??의 짙은 저주`는 의도한 이름이므로 임시 이름으로 고치지 않는다.
- 두억시니 무기는 검은 그림자 주먹이다.
- 손각시의 손과 손각시 머리카락은 별도 아이템이며 무기가 없으면 공격하지 않는다.
- 창귀는 갓 없는 일반 농노다. 산발, 절단된 팔·다리의 백골, 배의 호랑이 발톱 상처를 유지한다.
- 장비와 몬스터 이펙트는 제공된 원본과 Pixelfx 리소스를 우선 사용한다.

## 외부 코드와 라이선스

- pixelfx 원본: https://github.com/patch-gg/pixelfx.git, 기반 커밋 `a84159688af3ca37a4be05a0d422b94451b2e24e`.
- 생성기: `vendor/pixelfx/tools/export-geuseundae.mjs`. 라이선스와 출처는 루트 `THIRD_PARTY.md`를 유지한다.
