# 그슨대

한국 귀신을 소재로 한 Godot 횡스크롤 로그라이트 데모입니다. 현재 실행 대상은 `godot/project.godot`입니다. 루트 HTML 파일들은 초기 디자인 시안입니다.

## 실행

Godot 4.7.2에서 `godot/project.godot`을 열고 실행합니다. 기본 창은 640×360입니다. 기존 창의 크기와 위치를 유지해 주세요.

- 이동: A/D, 점프: Space, 대시: Shift (PC 키보드는 공격 조준 8방향, 마우스·모바일 스틱은 자유 각도). 점프 후 착지 전 Space를 다시 누르면 대시와 동일하게 동작
- 공격: J / 마우스 왼쪽, 심장: Q, 주무기/보조무기 스킬: F/G
- 상호작용: E, 가방: Tab/I, 재시작: R, 다음 시드: N
- 통합 시험장: F6 진입·복귀, `[ ]` 전 장비 43종 순회, `, .` 손각시·몽달귀신·창귀 전환, Tab 전 장비 가방, T 표적 초기화, P 두억시니 세트, F9 정지, Y 표적 AI. 시험장에서 바꾼 상태는 복귀할 때 원래 진행으로 되돌아간다.
- 전체 해금 실전 런: F7. 정상 시드 방·상점·층·보스 흐름으로 시작하며 가방에 전 장비 43종과 영혼조각 9999개가 들어 있다. `, .`로 손각시·몽달귀신·창귀를 실제 진행 중 자유롭게 바꾼다.

시드 기반 방 연결, 상점, 장비 41종(무기 33종 포함), 전투와 1챕터 보스, 영혼조각 자동 획득, 방 클리어 보상을 구현했습니다. 현재 저장 기능은 없으며 일부 아트와 밸런스는 데모 상태입니다.

## 이어서 개발

먼저 [최신 작업 인계](docs/CURRENT_STATUS.md), [개발 화면 선호](docs/development-preferences.md), [장비 원안](geuseundae_equipment.md)을 읽어 주세요. 현재 구현은 `godot/scripts`와 `docs/equipment-implementation.md`를 기준으로 확인합니다.

모바일 터치 조작과 Android/iOS 내보내기 프리셋이 있습니다. iOS Xcode 프로젝트 내보내기는 성공했으며 인증서와 실제 Team ID는 사용자가 Xcode에서 지정합니다. App Store용 정식 아이콘과 실기기 설치 검증은 남아 있습니다. 모바일 출력물과 Web 빌드는 Git에서 제외합니다.

이펙트 재생성: `node vendor/pixelfx/tools/export-geuseundae.mjs`. 출처와 라이선스는 [THIRD_PARTY.md](THIRD_PARTY.md)를 참고하세요.
