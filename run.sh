#!/bin/bash
swift build --configuration release
.build/release/Run serve --env production --port 8080 --hostname 0.0.0.0