 <a href="https://sublimesecurity.com"><img src="assets/sublime-logo.png" width="75px" alt="Sublime Logo" /></a>

Sublime Platform
==========
by [Sublime Security](https://sublime.security/)

Overview
---------
A free and open platform for detecting and preventing email attacks like BEC, malware, and credential phishing. Gain visibility and control, hunt for advanced threats, and collaborate with the community.

Sublime uses Message Query Language (MQL), a domain-specific language purpose-built for describing behavior in email. MQL is email provider agnostic, enabling defenders to write, run, and share Detections-as-Code.

Learn more about MQL: [Introduction to Message Query Language](https://sublime.security/blog/introduction-to-message-query-language-mql)

Docker Usage & Caveats
----------
This Docker deployment is intended for small-medium size deployments and for testing purposes ONLY (limited to 600 active mailboxes). For the best Sublime experience, we recommend the [AWS Cloud-native deployment](https://docs.sublime.security/docs/aws-cloudformation) or [Sublime Managed Cloud](https://docs.sublime.security/docs/sublime-managed), which can support any number of mailboxes, is resilient, and has the latest features. The docker deployment allows you to gain hands on experience, but will only receive best effort support (no long term support).

[Learn more about feature restrictions for Docker Compose](https://docs.sublime.security/docs/docker-requirements-and-limitations)

The Sublime Platform Docker Compose ships as an entire setup. Modifying the docker-compose file or using our docker images within your own implementation is not supported.

Setup
----------

```console
curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/main/install-and-launch.sh | sh
```

[View Docker Quickstart](https://docs.sublimesecurity.com/docs/quickstart-docker)

[View other deployment methods](https://sublime.security/start)

Detection rules
----------
Open-source detection rules and links to community Feeds are maintained in the [sublime-rules repo](https://github.com/sublime-security/sublime-rules).

Learn more
----------
- [Docs](https://docs.sublimesecurity.com)
- [API](https://docs.sublimesecurity.com/reference/introduction)
- [Release log](https://new.sublimesecurity.com)
- [Message Query Language (MQL)](https://docs.sublimesecurity.com/docs/message-query-language)
