#!/bin/bash
swift build --configuration release
.build/release/Run serve --env production --port 9000 --hostname 0.0.0.0