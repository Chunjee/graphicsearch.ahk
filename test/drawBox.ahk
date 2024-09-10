; writeOnScreen class
; writes numbers on screen mostly for debugging
class drawBox {
	__New(para_text, para_options) {
		; defaults
		if (!isObject(para_options)) {
			para_options := {x: 100, y: 100}
		}
		if (!para_options.timeout) {
			para_options.timeout := 4200
		}

		this.timer := ObjBindMethod(this, "timeout")
		this.name := this.hash([para_text, para_options])
		l_name := this.name

		; create gui
		gui, box%l_name%0: color, % para_options.color
		gui, box%l_name%1: color, % para_options.color
		gui, box%l_name%1: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
		gui, box%l_name%2: color, % para_options.color
		gui, box%l_name%2: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
		gui, box%l_name%3: color, % para_options.color
		gui, box%l_name%3: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
		gui, box%l_name%4: color, % para_options.color
		gui, box%l_name%4: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000

		; set dimensions
		Thickness := 4
		Offset := 0
		if (para_options.width < 0) {
			para_options.x += para_options.width
			para_options.width *= -1
		}
		if (para_options.height < 0) {
			para_options.y += para_options.height
			para_options.height *= -1
		}
		if (Thickness >= 2) {
			if (O == "O") {
				para_options.x -= Thickness
				para_options.y -= Thickness
				para_options.width += Thickness
				para_options.height += Thickness
			}
			if (O == "C") {
				para_options.x -= Thickness / 2
				para_options.y -= Thickness / 2
			}
			if (O == "I") {
				para_options.width -= Thickness
				para_options.height -= Thickness
			}
		}
		
		gui, box%l_name%1:show, % "x" para_options.x " y" para_options.y " w" para_options.width " h" Thickness " NA", Horizontal 1
		gui, box%l_name%2:show, % "x" para_options.x " y" para_options.y + para_options.height " w" para_options.width + Thickness " h" Thickness " NA", Horizontal 2
		gui, box%l_name%3:show, % "x" para_options.x " y" para_options.y " w" Thickness " h" para_options.height " NA", Vertical 1
		gui, box%l_name%4:show, % "x" para_options.x + para_options.width " y" para_options.y " w" Thickness " h" para_options.height " NA", Vertical 2

		timeRef := this.timer
		setTimer % timeRef, % "-"para_options.timeout
		return
	}

	timeout() {
		l_name := this.name
		; hide 
		gui, box%l_name%1:destroy
		gui, box%l_name%2:destroy
		gui, box%l_name%3:destroy
		gui, box%l_name%4:destroy
	}

	hash(dataArray)
	{
		data := ""
		
		; Process each element in the array
		for index, value in dataArray {
			if isObject(value) {
				; Append object key-value pairs to the data string
				for key, val in value
					data .= key . val
			} else {
				; Append non-object values directly
				data .= value
			}
		}
		
		; Simple hash calculation using bitwise operations
		hash := 0
		for index, char in StrSplit(data) {
			hash := (hash * 31) ^ Asc(char)
		}
		
		; Return hash in hexadecimal format
		return Format("{:08X}", hash & 0xFFFFFFFF)
	}
}