# 새 세션 인계 · 2026-11-03

## 현재 요청과 보류

GitHub BackiiMu/geuseundae에 소스를 푸시하고 인계한다. APK 제작, 연결 Android 설치, iOS Xcode 내보내기는 사용자가 “푸시만 해놔 나머진 나중에”라고 하여 중단했다. 모바일 관련 수정은 미완성 상태로 보존한다.

## 실제 게임

- Godot 4.7.2, `godot/project.godot`, 시작 장면 `scenes/village.tscn`.
- `random_run.gd`: 마을/런/장비 실험실, `run_generator.gd`: 시드 생성, `room_catalog.gd`, `room_view.gd`: 방과 동선.
- `combat_director.gd`: 전투/UI, `equipment_db.gd`와 `equipment_runtime.gd`: 장비 데이터와 동작, `combat_enemy.gd`: 적/보스.
- `actor_sprite.gd`: 캐릭터 시트 애니메이션. 텍스처를 중복 곱하면 검게 변하므로 셰이더 수정 주의.
- `pixel_vfx.gd`: 23종 효과 시트. 원본은 `vendor/pixelfx/src/fx/geuseundae`, 생성기는 `vendor/pixelfx/tools/export-geuseundae.mjs`.
- 장비 원안은 루트 `geuseundae_equipment.md`. 의도적으로 깨진 두억시니 장비 이름을 유지한다. 두억시니 무기는 검은 그림자 주먹이다.
- 시드 1103 정상 루트: forest 0 → shrine 1 → 상점 3 → gallery 4 → 보스 8. 각 맵의 이동 포탈은 1~4개이며 한 구간의 방 개수를 의미하지 않는다.
- 손각시 심장 HP60, Q는 화면 내 적을 머리카락으로 앞으로 끌며 쿨타임 30초.
- 장비 자동 가방 획득, 파기는 경고 후 영구 제거. 상점은 마을 1/2등급 4개 세션 랜덤, 층 상점은 시드 기반. 저장 기능은 아직 없다.

## 검수 기록과 제한

이전 작업에서 실제 Godot Web 데모를 조작해 일반 경로로 보스까지 클리어했다. 장비/전투/적 AI/상점/방 생성/상단 동선/8방향 대시/이펙트 관련 `godot/tests` 검사를 통과했다. 이 기록은 모바일 수정 전 기준이며 이번 푸시 과정에서 전체 재실행하지 않았다.

보스 외형은 전사 확대 버전이며 별도 보스 시트가 필요하다. 아트·전투 밸런스는 계속 검토해야 한다. 루트 HTML은 과거 시안이며 현재 게임과 혼동하지 않는다. `godot/README.md`와 오래된 제안 문서는 최신 구현과 다를 수 있다.

## 모바일 준비 상태 — 미검증

`mobile_controls.gd`와 모바일 조준 분기, landscape 설정, Android/iOS 프리셋을 추가했다. 첫 Android 내보내기는 ETC2/ASTC import 설정 누락, 첫 iOS 내보내기는 Team ID 누락으로 실패했다. 압축 import 설정은 추가했으나 성공한 APK/Xcode 결과물과 기기 설치 검증은 없다. iOS Team ID는 빈 값으로 보관했다. 실제 개발팀 ID를 선택해야 한다.

개발 환경에 Godot export templates 4.7.2, Xcode, Android SDK가 있다. Android SDK 기본 위치는 `~/Library/Android/sdk`; Java는 Android Studio JBR 또는 Homebrew openjdk@17 사용 가능. 연결 Android는 SM-A826S로 확인했었다. 인증서·키·개인 설정·빌드 산출물은 커밋하지 않는다.

## 작업 재개

창 크기와 위치 선호를 반드시 유지한다. 모바일 재개를 요청받으면 우선 import/문법 검사, 터치 입력 검수, Android export/설치/실행 검증, iOS 실제 팀 선택과 Xcode export 순서로 진행한다. 완료 전 성공했다고 기록하지 않는다.

테스트 예시: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/equipment_test.gd`.

## 외부 코드

pixelfx 원본 https://github.com/patch-gg/pixelfx.git, 기반 커밋 `a84159688af3ca37a4be05a0d422b94451b2e24e`. 프로젝트 전용 효과와 내보내기 도구를 수정했다. 일반 소스로 포함하며 라이선스/NOTICE를 보존한다.
