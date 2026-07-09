---
trigger: always_on
---

### 터미널 명령어 모음

#### 작업을 시작할 때
// 매일 아침 제일 먼저 입력할 것
```
git checkout main
git pull origin main
// 다른 팀원들이 각자 집에서 수정한 내용을 내 컴퓨터에 다운받음.
```

// 1. 새로운 작업을 막 시작할 때
```
git checkout -b [브랜치 이름] // 새로운 브랜치를 생성하고 이동함.
```

// 2. 전에 만든 브랜치로 돌아가 이어서 작업할 때
```
git checkout [브랜치 이름]
```

#### 수정 내용 업로드
```
git status // 내가 어떤 파일을 수정했는지 확인
git add . 
// 수정한 모든 파일을 업로드 대기 상태로 만듬.
// 또는 온점 대신 폴더명/파일명을 하나하나 입력해 추가해도 무방함.
git commit -m "[커밋 메세지]"
git push origin [브랜치 이름]
```

#### PR 작성하기
// !!!! PR까지 작성해야 하루 작업이 끝남 !!!!
// PR 작성은 웹 브라우저에서 작업함. 터미널에서 하는 방법도 있으나 본 문서에서는 생략
1. GitHub 저장소에 접속 (https://github.com/A-I-capstone/2026-capstone-a-i-client)
2. 화면 상단의 Compare & pull request 버튼 클릭
3. 작업 내용을 간단히 적은 뒤 Create pull request 클릭
4. 팀원이 확인 후 main 브랜치에 반영함

---

### 브랜치 & 커밋 메세지 규칙

#### 브랜치 네이밍 규칙
- 구조: [작업 유형]/[세부 사항]
- 규칙: 띄어쓰기 대신 하이픈 (-) 사용. 대문자 사용 금지.

예)
- docs/readme-update
- feat/parent-controls
- style/background-color

#### 커밋 메세지 규칙
- 구조: [타입]: [작업 내용]
- 규칙:
   - 타입 뒤에 콜론과 한 칸 공백 (: ) 필수
   - 현재형으로 기술 (추가함/added X, 추가/add O)
   - 끝에 마침표 찍지 않음
   - 영어를 권장하나, 부득이한 경우 작업 내용만 한국어로 작성 가능
- 사용 가능한 type: 
   - feat: 새로운 기능 추가
   - fix: 버그/오류 수정
   - refactor: 기능 변경 없이 코드 구조 변경
   - style: UI 수정
   - test: 테스트 파일 생성 및 수정
   - docs: 문서 생성 및 수정
   - build: 빌드 관련 수정
   - chore: 위 내용에 해당하지 않는 모든 잡무

---

### 트러블슈팅

#### 실수로 이상한 파일까지 git add . 했을 때
```
git restore --staged . // add하기 전 상태로 되돌림. 내가 짠 코드는 지워지지 않음
```

#### 커밋 메세지에 오타 / 잘못 작성했을 때
```
// push하기 전에만 사용 가능!
git commit --amend -m "[수정된 커밋 메세지 작성]"
```

#### 뭔가 단단히 잘못됨. 오늘의 모든 작업 내용을 삭제하고 처음 상태로 리셋할 때
```
git reset --hard HEAD
// 로컬 컴퓨터의 모든 변경 사항이 버려짐. 즉 작업 내용이 날아감!!! 주의해서 꼭 필요할 때만 사용
```

---

// 아래 내용은 Gemini 및 AI 에이전트를 위한 설명으로, 인간 팀원은 읽지 않아도 무방함

### Instructions for AI Agents

1. DO NOT USE `git reset --hard` or any force push commands.
2. Use English when writing commit message. Follow the conventions strictly.
3. Before executing ANY Git command, you MUST present a brief explanation and a **Quantified Risk Assessment** to the user, and wait for user confirmation if the Risk Score is 3 or higher. Use the following format:

**Format:**
   - **Command:** `git <command>`
   - **Purpose:** <Brief description of what this command does>
   - **Risk Score:** [1 to 5] / 5
   - **Risk Assessment:** <Brief explanation of potential data loss or workflow disruption>

**Risk Score Framework:**
   - **1/5 (Safe / Read-only):** `git status`, `git diff`, `git log`. No changes are made to the codebase.
   - **2/5 (Local Navigation & Staging):** `git checkout [existing-branch]`, `git add`. Easily reversible, zero risk of data loss.
   - **3/5 (Local State Mutation):** `git commit`, `git checkout -b`. Creates new local history or branches. Requires basic attention.
   - **4/5 (Remote Sync & History Modification):** `git pull`, `git push`, `git commit --amend`. Interacts with the remote repository or modifies recent history. Potential for merge conflicts or minor confusion.
   - **5/5 (Destructive / Irreversible):** `git reset --hard` or any destructive action. High risk of permanent data loss or breaking the team's shared history. (Reminder: AI is strictly forbidden from executing this).