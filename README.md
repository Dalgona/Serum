# Serum

**Serum** is a simple static website generator written in [Elixir](http://elixir-lang.org).

Like some of other static website generators, Serum focuses on blogging. And if you know how to write markdown documents and how to handle EEx templates, you can easily build your own website.

## Getting Started

### Requirement

* Elixir 1.3 or newer

    Determined by current development environment. Could support lower versions after tests.

### Initializing and Building the Project

1. Use `git` to clone this repository.

    ```sh
    % git clone https://github.com/Dalgona/Serum.git
    ```

2. Type the commands below to fetch the dependencies and build Serum. The `serum` executable will be created under your PWD.

    ```sh
    % cd Serum
    % mix deps.get
    % mix escript.build
    ```

3. Execute `serum init [directory]` to create a new Serum project at current or specified directory.

    > *It is NOT recommended to initialize a new project to where Serum repository is located.*

    ```sh
    % ./serum init /path/to/project
    ```

4. Type `serum build [directory]` to build the generated project.

    ```sh
    % ./serum build /path/to/project
    ```

    When the build completes, the root of your website will be created under `/path/to/project/site` directory. Copy the contents of this directory to your own www directory, or upload them to the external web hosting service.

### Configuration

When you initialize a new project, Serum will create directory/file structure described below:

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

`serum.json` holds information about the current project, which looks like:

```json
{
  "site_name": "New Website",
  "site_description": "Welcome to my website!",
  "author": "Dalgona.",
  "author_email": "dalgona@hontou.moe",
  "base_url": "/site/"
}
```

* `site_name` &mdash; The title of your website.
* `site_description` &mdash; The description of your website. Can be used as a subtitle.
* `author_name` &mdash; The name of author of blog posts.
* `author_email` &mdash; The email address of the author.
* `base_url` &mdash; The base path of your web site. I recommend you to put a trailing `/`.

> These attributes can be referenced by using template tags like `<%= @site_name %>`.

### Adding Pages to Your Website

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

사이트를 빌드하면 `posts/` 디렉토리의 각각의 마크다운 파일들이 HTML로 변환되고 `templates/post.html.eex` 템플릿에 적용된 후, 다시 `templates/base.html.eex` 템플릿과 결합하여 `site/posts/` 디렉토리에 저장됩니다.

### 템플릿

Serum은 네 개의 템플릿(`base.html.eex`, `list.html.eex`, `post.html.eex` 및 `nav.html.eex`)을 사용하여 웹 페이지들을 만듭니다. 새로운 프로젝트를 생성하면 프로젝트의 `templates/` 디렉토리에 최소한의 기능이 구현된 템플릿이 같이 생성되는데, 이 템플릿 파일에는 Serum에서 제공하는 모든 템플릿 변수들이 다 사용되고 있으므로 이를 참고하여 여러분만의 페이지 템플릿을 만드세요. 각 템플릿 파일의 역할은 아래와 같습니다.

* `base.html.eex` &mdash; 웹 사이트의 전반적인 구조와 디자인을 담당합니다. HTML 루트 태그가 이 템플릿에 정의되어 있습니다.
* `list.html.eex` &mdash; 등록된 모든 블로그 포스트의 목록입니다.
* `post.html.eex` &mdash; 블로그 포스트 페이지 템플릿입니다.
* `nav.html.eex` &mdash; 사이트의 내비게이션 영역에 들어갈 내용입니다.

### 애셋과 미디어

`assets` 디렉토리에는 프로젝트에서 사용하는 스타일시트나 자바스크립트, 이미지와 같은 리소스를 저장할 수 있습니다. 프로젝트를 생성하면 편의를 위해 `assets` 디렉토리 안에 `css`, `js`, `images` 디렉토리가 같이 만들어지지만, 여러분의 필요에 따라 내부 디렉토리 구조를 변경해도 큰 상관은 없습니다. `assets` 디렉토리는 프로젝트를 빌드할 때 `site/assets/` 디렉토리로 그대로 복사되므로 템플릿 내에서 `href="<%= @base_url %>assets/css/style.css"`와 같은 방법으로 참조할 수 있습니다.

`media` 디렉토리에는 블로그 포스트에서 참조될 사진들이 저장됩니다. 포스트에 삽입할 사진을 이 디렉토리 아래에 집어 넣으면 마크다운 문서에서 `%media:` 문법으로 해당 사진 파일을 가리킬 수 있습니다. 예를 들면, `![Image](%media:foo.jpg)` 이 코드는 HTML로 변환되기 전에 `![Image](/base/url/media/foo.jpg)`로 확장됩니다.

> **참고**: 구현상의 제약에 의해, `%media:` 참조를 사용하는 경우에는 이미지의 대체 텍스트에 `]` 문자를 사용하거나, 이미지의 원본 URL에 `)` 문자를 사용하면 예기치 않은 결과가 발생할 수도 있습니다.

## TODO

* 본 문서의 영어판 작성
* TODO 생각해내기

## 개발자 연락처

* Email: <dalgona@hontou.moe>
* Twitter: [@d57pub_](https://twitter.com/d57pub_)
