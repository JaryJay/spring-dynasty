class_name Strings

static func pad(s: String, num: int) -> String:
	return "...................".substr(0, num - s.length()) + s
