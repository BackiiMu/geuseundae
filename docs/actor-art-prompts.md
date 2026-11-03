# 손각시와 1챕터 일반 몹 도트

2026-11-03. 내장 image_gen 도구로 투명 래스터 원본 4장을 생성했다. CLI/API 대체 경로는 사용하지 않았다. 손각시를 먼저 생성하고 다른 세 캐릭터에 스타일 참고 이미지로 제공했다. 기존 게임 캐릭터를 복제하지 않는 새 디자인이다.

## 저장한 원본

- 손각시: `godot/assets/actors/source/songaksi-v1.png`
- 퇴마 무사: `godot/assets/actors/source/warrior-v1.png`
- 부적 도사: `godot/assets/actors/source/adept-v1.png`
- 목탁 승려: `godot/assets/actors/source/monk-v1.png`

각 원본은 1536×1024 RGBA, 8열×4행, 32프레임이다. 셀 192×256을 게임에서 48×64로 nearest 표시한다. 발 기준점은 (24,62)이며 기존 이동·점프·대시·충돌 크기를 유지했다. 선봉대장은 이번 작업에서 별도 신규 디자인을 생성하지 않고 무사 도트를 기존 1.5배 규칙으로 재사용한다.

## 생성 프롬프트 세트

### 공통 레이아웃·스타일

Use case: stylized-concept. Asset type: production pixel-art sprite animation atlas for an original Korean ghost side-scrolling action game. STRICT layout: landscape 1536×1024, exactly 8 equal columns and 4 equal rows, 32 cells of 192×256. Character centered at x96 inside each cell, common feet baseline near y240, all parts safely inside each cell. All poses face RIGHT in three-quarter side view. Crisp 4×4 blocks representing logical pixels, hard one-pixel outlines, clustered four-step shading, restrained dark fantasy palette, effective character height about 46–50 logical pixels. Consistent identity and proportions across every frame. Genuine transparent background; no scene, ground shadows, labels, text, grid, or baked-in VFX. No smooth brushwork or glow. Original characters, not existing game sprites.

Row1: eight idle breathing frames. Row2: eight chronological run/walk frames, clearly alternating feet and trailing cloth. Row3: eight attack frames: first two anticipation, next two release, last four recovery. Row4: hurt/knockback/stagger poses. For the heroine specifically, row4 instead contains two rising jump, two falling, two forward dash, two hurt poses. Image1 is a style reference only when used for the three enemies.

### 손각시

A small eerie maiden ghost: long near-black blue-violet hair partly covering a pale face, one tiny dim crimson eye, worn ivory jeogori and flowing ivory chima hanbok, small muted red chest ribbon, bare gray feet. Delicate haunted silhouette, dignified, not sexy and not a cute mascot. About 46 logical pixels high, head about 12 logical pixels. Idle: restrained bobbing hair and cloth. Run: alternating knees and feet with hair and skirt trailing. Attack: pull arm/hair back, sharp forward release, recover; no detached VFX or weapon baked into sheet. Air poses: tuck legs on ascent, legs down and hair up on fall, body lean and streaming hair on dash, recoil on hurt.

### 퇴마 무사

A Korean exorcist footsoldier. Adult male, lean sturdy silhouette, charcoal black Korean gat hat with readable wide brim, dark desaturated navy jeogori, pale gray trousers, faded crimson belt and hanging charm, dark shoes. Short steel Korean geom sword held one-handed, not a katana, no samurai armor. A deliberate overhead-to-forward sword cut. Worn fabric, strong readable shapes, restrained palette. Menacing but human, not cute.

### 부적 도사

A Korean talisman exorcist. Adult gaunt male, tall narrow silhouette, long desaturated indigo-violet ritual robe, high dark cloth ritual headwear, warm ochre paper talismans in right hand and hanging from belt, pale face and dark brows. No sword. Attack draws the paper toward the chest then snaps hand forward to throw it; no flying projectile baked into sheet. Long sleeves and hem sway while walking. Ochre-paper accent distinguishes the ranged role.

### 목탁 승려

A heavy Korean wooden-moktak exorcist monk. Adult bald broad stocky silhouette, muted slate brown-gray layered Buddhist robe, dark wooden prayer beads at neck, large dark reddish wooden moktak percussion block and short wooden beater. No sword or gun. Attack raises the implement with both arms then swings down and forward forcefully, with bent-knee anticipation and heavy recovery. Low broad stance, cloth weight and shaved head distinguish this slow tough melee role.

## 게임 연결 및 검수

- `actor_sprite.gd`: 상태별 행 선택, 좌우 반전, 공격 준비/타격/회복, 피격 플래시·무적 깜빡임, 정지 시 애니메이션 정지.
- 손각시: 대기·달리기·공격·상승·하강·대시·피격. 장비 이펙트와 별도로 몸의 자세를 표시한다.
- 일반 몹: 무사 HP30/피해8, 도사 HP20/피해6, 승려 HP60/피해12/이동65/준비0.9초. 승려 수치는 이전 제안에서 가져온 데모값이다.
- 첫 방의 기존 입문 구성을 유지하고 후속 방에 세 종류를 혼합 배치했다.
- 시험장 T는 세 종류의 HP120 표적, Y는 실제 AI 동작 전환. 시험장 피격 면역은 유지한다.
- 실행 검수에서 셰이더의 색 중복 곱셈으로 원본보다 어두워지는 문제를 수정했다. 기존 창 크기·위치는 변경하지 않았다.
- `actor_test.gd`는 네 원본 로드, 상태별 프레임 선택, 정지, 세 몹 준비·회복, 실제 승려 12 피해를 검증한다. 기존 장비·전투·대시·하강 검사도 통과했다.
- 실제 조작 검수: 시험장에서 Y로 세 종류 AI를 켜고 공격·피격, 점프와 위쪽 대시를 확인했다. 일반 회차는 마을 → 결계 숲길 → 오래된 신당 → 상점 → 끊어진 회랑 → 보스 처치 → 보상 수령 → 2층까지 진행했다. HP24, 영혼조각35를 남겼으며 이 회차에는 F8이나 시험장 장비를 사용하지 않았다.
