# Serum

**Serum**은 [Elixir](http://elixir-lang.org)로 작성된 간단한 정적 웹사이트 생성기입니다.

Serum은 몇몇 다른 정적 사이트 생성기와 마찬가지로 블로그 기능에 중점을 두고 있으며, 마크다운 문서를 작성하는 법과 EEx(Embedded Elixir) 템플릿을 다루는 법만 알고 있으면 손쉽게 사이트를 만들 수 있습니다.

## 시작하기

### 요구사항

* Elixir 1.3 이상

    이는 현재 개발 환경에 의해 지정되었으며, 차후 테스트를 통해 요구되는 최소 버전이 더 낮아질 수 있습니다.

### 프로젝트 생성 및 빌드

1. 먼저 `git`을 이용하여 로컬에 이 저장소를 복제하세요.

    ```sh
    % git clone https://github.com/Dalgona/Serum.git
    ```

2. 복제된 저장소에 들어가서 아래 명령을 입력하여 의존하는 모듈을 내려받고 Serum을 빌드하면 현재 디렉토리에 `serum` 실행 파일이 생성됩니다.

    ```sh
    % cd Serum
    % mix deps.get
    % mix escript.build
    ```

3. `serum init [directory]` 명령을 실행하면 현재 디렉토리 또는 지정한 디렉토리에 새로운 Serum 프로젝트를 생성할 수 있습니다.

    > *Serum 저장소가 위치한 디렉토리에 프로젝트를 생성하는 것은 권장되지 않습니다.*

    ```sh
    % ./serum init /path/to/project
    ```

4. `serum build [directory]`명령으로 생성된 프로젝트를 빌드합니다.

    ```sh
    % ./serum build /path/to/project
    ```

    빌드가 완료되면 `/path/to/project/site` 디렉토리에 웹사이트의 루트가 생성됩니다. 이 디렉토리의 내용물을 여러분이 사용하고 있는 웹 서버의 www 디렉토리로 복사하거나 외부 호스팅 서비스에 업로드하세요.

### 프로젝트 설정하기

프로젝트 초기화가 완료되면 해당 디렉토리 아래에 아래와 같은 구조가 생성됩니다.

```text
/path/to/project/
|-- serum.json
|-- posts
|-- pages
|   |-- pages.json
|   +-- index.md
|-- templates
|   |-- base.html.eex
|   |-- list.html.eex
|   |-- post.html.eex
|   +-- nav.html.eex
|-- assets
|   |-- css
|   |-- js
|   +-- images
+-- media
```

`serum.json` 파일에는 현재 프로젝트 (웹 사이트)의 정보를 담고 있습니다. 이 파일의 구조는 아래와 같습니다.

```json
{
  "site_name": "New Website",
  "site_description": "Welcome to my website!",
  "author": "Dalgona.",
  "author_email": "dalgona@hontou.moe",
  "base_url": "/site/"
}
```

* `site_name` &mdash; 웹 사이트의 제목입니다.
* `site_description` &mdash; 웹 사이트에 대한 설명입니다. 부제목으로 이용할 수도 있습니다.
* `author_name` &mdash; 포스트 작성자의 이름입니다.
* `author_email` &mdash; 포스트 작성자의 이메일 주소입니다.
* `base_url` &mdash; 웹 사이트의 기준 경로입니다. 경로의 끝에 `/`를 붙이는 것을 권장합니다.

> 위 속성들은 템플릿에서 `<%= @site_name %>`과 같은 방법으로 접근할 수 있습니다.

### 사이트에 페이지 추가하기

`pages/` 디렉토리에는 블로그 포스트를 제외한 웹 사이트를 구성하는 기타 페이지의 소스 코드를 추가할 수 있습니다. 마크다운(파일 이름이 `.md`로 끝나야 함)과 HTML(파일 이름이 `.html`로 끝나야 함) 이 두 가지의 파일 형식을 지원하며, 프로젝트를 빌드하면 해당 파일의 내용이 `templates/base.html.eex` 템플릿과 결합하여 완성된 페이지가 사이트의 루트 디렉토리(`site/`)에 생성됩니다.

페이지가 사이트에 제대로 표시되게 하기 위해서는 `pages/` 디렉토리 내에 `pages.json` 파일도 적절하게 만들어 주어야 합니다. 이 파일에는 각각의 페이지의 제목과 해당 페이지가 사이트의 내비게이션 영역에 어떻게 표시되는지에 대한 정보가 포함되어 있습니다. 이 파일의 구조는 아래와 같습니다.

```js
[
  // ...,
  {
    "name": "index",
    "type": "html",
    "title": "Welcome",
    "menu": false,
    "menu_text": "About",
    "menu_icon": "assets/images/menu_index.png"
  },
  // ...
]
```

* `name` &mdash; 페이지 소스 파일의 이름입니다.
* `type` &mdash; 페이지 소스 파일의 확장자입니다. `"html"`이나 `"md"`중 하나만 사용 가능합니다.
* `title` &mdash; 웹 브라우저의 제목 표시줄에 나타나는 텍스트입니다.
* `menu` &mdash; 해당 페이지의 링크가 내비게이션 영역에 나타날지를 결정합니다. 템플릿에 따라 무시될 수도 있습니다.
* `menu_text` &mdash; 내비게이션 영역에 나타나는 링크 텍스트입니다.
* `menu_icon` &mdash; 내비게이션 영역에 나타나는 이미지의 경로입니다. 템플릿에 따라 무시될 수도 있습니다.

> `pages/` 디렉토리에 페이지 소스 파일이 저장되어 있어도 `pages.json`에 해당 파일에 대한 정보가 정의되어 있지 않으면 빌드 시 사이트에 포함되지 않습니다.

### 새 포스트 작성하기

`posts/` 디렉토리에 여러분이 작성할 블로그 포스트의 마크다운 파일이 저장됩니다. 이 디렉토리 내에 저장되는 파일은 모두 `yyyy-MM-dd-hhmm-title-slug.md`의 규칙을 따라야 합니다. 각각의 마크다운 파일의 첫 줄은 반드시 `#` 문자, 공백(`'\x20'`), 그리고 해당 포스트의 제목으로 이루어져 있어야 합니다. Serum은 마크다운 파일의 첫 줄을 처리하여 포스트의 메타데이터를 생성합니다.

아래는 유효한 마크다운 파일의 예시입니다.

`2016-08-01-1946-my-new-post.md:`

```markdown
# 안녕하세요! 나의 첫 포스트입니다

Lorem ipsum dolor sit amet, consectetur adipiscing ...
```

사이트를 빌드하면 `posts/` 디렉토리의 각각의 마크다운 파일들이 HTML로 변환되고 `templates/post.html.eex` 템플릿에 적용된 후, 다시 `templates/base.html.eex` 템플릿과 결합하여 `site/posts/` 디렉토리에 저장됩니다. 또한 사이트가 빌드될 때 모든 포스트의 목록이 포함된 `site/posts/index.html` 파일도 생성됩니다.

### 템플릿

Serum은 네 개의 템플릿(`base.html.eex`, `list.html.eex`, `post.html.eex` 및 `nav.html.eex`)을 사용하여 웹 페이지들을 만듭니다. 새로운 프로젝트를 생성하면 프로젝트의 `templates/` 디렉토리에 최소한의 기능이 구현된 템플릿이 같이 생성되는데, 이 템플릿 파일에는 Serum에서 제공하는 모든 템플릿 변수들이 다 사용되고 있으므로 이를 참고하여 여러분만의 페이지 템플릿을 만드세요. 각 템플릿 파일의 역할은 아래와 같습니다.

* `base.html.eex` &mdash; 웹 사이트의 전반적인 구조와 디자인을 담당합니다. HTML 루트 태그가 이 템플릿에 정의되어 있습니다.
* `list.html.eex` &mdash; 등록된 모든 블로그 포스트의 목록입니다.
* `post.html.eex` &mdash; 블로그 포스트 페이지 템플릿입니다.
* `nav.html.eex` &mdash; 사이트의 내비게이션 영역에 들어갈 내용입니다.

### 애셋과 미디어

`assets/` 디렉토리에는 프로젝트에서 사용하는 스타일시트나 자바스크립트, 이미지와 같은 리소스를 저장할 수 있습니다. 프로젝트를 생성하면 편의를 위해 `assets/` 디렉토리 안에 `css`, `js`, `images` 디렉토리가 같이 만들어지지만, 여러분의 필요에 따라 내부 디렉토리 구조를 변경해도 큰 상관은 없습니다. `assets/` 디렉토리는 프로젝트를 빌드할 때 `site/assets/` 디렉토리로 그대로 복사되므로 템플릿 내에서 `href="<%= @base_url %>assets/css/style.css"`와 같은 방법으로 참조할 수 있습니다.

`media/` 디렉토리에는 블로그 포스트에서 참조될 사진들이 저장됩니다. 포스트에 삽입할 사진을 이 디렉토리 아래에 집어 넣으면 마크다운 문서에서 `%media:` 문법으로 해당 사진 파일을 가리킬 수 있습니다. 예를 들면, `![Image](%media:foo.jpg)` 이 코드는 `<img src="/base/url/media/foo.jpg" alt="Image">`로 확장됩니다.

> **참고**: 구현상의 제약에 의해, `%media:` 참조를 사용하는 경우에는 이미지의 원본 URL에 `"` 문자를 사용하면 예기치 않은 결과가 발생할 수도 있습니다.

## TODO

* TODO 생각해내기

## 개발자 연락처

* Email: <dalgona@hontou.moe>
* Twitter: [@d57_kr](https://twitter.com/d57_kr)
