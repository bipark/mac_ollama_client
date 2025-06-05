<div align='center'>


# ✨ LLM Hippo - 멀티 LLM 클라이언트 ✨

_Ollama, LM Studio, Claude, OpenAI를 지원하는 멀티 플랫폼 Mac 클라이언트_

[ENGLISH](README.md) •
[한국어](README_KR.md) •
[日本語](README_JP.md) •
[中文](README_CH.md)

</div>

#  LLM Hippo

LLM Hippo는 Ollama, LM Studio, Claude, OpenAI 등 다양한 LLM 서비스에 연결할 수 있는 Mac 클라이언트 앱입니다. 소스 코드를 다운로드하여 직접 빌드하거나 [Apple App Store](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)에서 LLM Hippo 앱을 다운로드할 수 있습니다.

##  소개

LLM Hippo는 다양한 LLM 플랫폼을 지원하는 다목적 클라이언트입니다:
- Ollama: 로컬에서 LLM을 실행할 수 있는 오픈소스 소프트웨어
- LM Studio: 다양한 모델을 지원하는 로컬 LLM 플랫폼
- Claude: Anthropic의 고급 AI 모델
- OpenAI: GPT 모델을 포함한 선도적인 AI 플랫폼

![포스터](image_en.jpg)

## 주요 기능

- **다중 LLM 플랫폼 지원**:
  - Ollama를 통한 로컬 LLM 접근 (http://localhost:11434)
  - LM Studio 통합 (http://localhost:1234)
  - Claude API 지원
  - OpenAI API 지원
- **선택적 서비스 표시**: 모델 선택 메뉴에 표시할 LLM 서비스 선택 가능
- 원격 LLM 접근: IP 주소를 통해 Ollama/LM Studio 호스트에 연결
- 사용자 정의 프롬프트: 커스텀 지시사항 설정 지원
- 다양한 오픈소스 LLM 지원 (Deepseek, Llama, Gemma, Qwen, Mistral 등)
- 사용자 정의 가능한 지시사항 설정
- **고급 모델 매개변수**: 직관적인 슬라이더로 Temperature, Top P, Top K 제어
- **연결 테스트**: 내장된 서버 연결 상태 확인 기능
- **다중 형식 파일 지원**: 이미지, PDF 문서, 텍스트 파일
- 이미지 인식 지원 (지원하는 모델에 한함)
- 직관적인 채팅형 UI
- 대화 기록: 채팅 세션 저장 및 관리
- 한국어, 영어, 일본어, 중국어 지원
- 마크다운 형식 지원

![poster](image_settings.jpg)

##  사용 방법

1. 선호하는 LLM 플랫폼 선택:
   - Ollama: 컴퓨터에 Ollama 설치 ([Ollama 다운로드](https://ollama.com/download))
   - LM Studio: LM Studio 설치 ([LM Studio 웹사이트](https://lmstudio.ai/))
   - Claude/OpenAI: 각 플랫폼에서 API 키 획득
2. 소스를 다운로드하여 Xcode로 빌드하거나 [App Store](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)에서 LLM Hippo 앱 다운로드
3. 선택한 플랫폼 구성:
   - Ollama/LM Studio: 원하는 모델 설치
   - Claude/OpenAI: 설정에 API 키 입력
4. 로컬 LLM(Ollama/LM Studio)의 경우 필요시 원격 접근 구성
5. LLM Hippo를 실행하고 원하는 서비스와 모델 선택
6. 대화 시작!

##  시스템 요구사항

- 로컬 LLM: Ollama 또는 LM Studio가 설치된 컴퓨터
- 클라우드 LLM: Claude 또는 OpenAI의 유효한 API 키
- 네트워크 연결

## 장점

- 로컬 및 클라우드 기반 LLM을 위한 멀티 플랫폼 지원
- 간소화된 인터페이스를 위한 유연한 서비스 선택
- 다양한 플랫폼을 통한 고급 AI 기능 사용 가능
- 프라이버시 보호 옵션 (로컬 LLM)
- 프로그래밍, 창작 작업, 일상적인 질문 등에 다용도로 활용
- 체계적인 대화 관리

## 참고사항

- 로컬 LLM 기능은 Ollama 또는 LM Studio 설치 필요
- Claude 및 OpenAI 서비스는 API 키 필요
- 로컬 LLM 호스트와 API 키의 안전한 관리는 사용자 책임

##  앱 다운로드 

- 구축에 어려움을 겪는 분들은 아래 링크에서 앱을 다운로드할 수 있습니다.
- [https://apps.apple.com/us/app/mac-ollama-client/id6741420139](https://apps.apple.com/us/app/mac-ollama-client/id6741420139)

## 라이선스

LLM Hippo는 GNU 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 연락처

LLM Hippo에 대한 문의나 버그 리포트는 rtlink.park@gmail.com으로 이메일을 보내주세요.

