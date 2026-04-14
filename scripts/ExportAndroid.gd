extends SceneTree

const OUTPUT_PATH := "res://build/android/demo-godot-debug.apk"


func _init() -> void:
	call_deferred("_wait_and_export")


func _wait_and_export() -> void:
	await create_timer(2.0).timeout

	var platform := EditorExportPlatformAndroid.new()
	var preset := platform.create_preset()

	preset.set("package/unique_name", "com.starquantix.gameoflife")
	preset.set("package/name", "Game of Life")
	preset.set("package/signed", true)
	preset.set("architectures/arm64-v8a", true)
	preset.set("architectures/armeabi-v7a", false)
	preset.set("architectures/x86", false)
	preset.set("architectures/x86_64", false)
	preset.set("gradle_build/use_gradle_build", false)
	preset.set("gradle_build/export_format", 0)
	preset.set("screen/immersive_mode", true)

	platform.clear_messages()
	var result := platform.export_project(preset, true, OUTPUT_PATH, 0)

	print("Export result: ", result)
	print("Output: ", OUTPUT_PATH)
	print("Message count: ", platform.get_message_count())
	for i in range(platform.get_message_count()):
		print("Message ", i, ": ", platform.get_message_text(i))

	quit(result)
