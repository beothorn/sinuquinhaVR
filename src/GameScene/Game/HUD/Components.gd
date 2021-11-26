extends Node2D


signal practice
signal quit

func _on_Practice_pressed():
	emit_signal("practice")


func _on_Quit_pressed():
	emit_signal("quit")
