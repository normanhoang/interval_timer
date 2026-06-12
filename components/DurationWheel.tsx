import { Picker } from "@react-native-picker/picker";
import { View } from "react-native";
import { useThemeColors } from "../lib/theme";

const HOURS = Array.from({ length: 24 }, (_, i) => i);
const SIXTY = Array.from({ length: 60 }, (_, i) => i);

interface Props {
  seconds: number;
  onChange: (seconds: number) => void;
}

/** Three side-by-side rotary wheels: hr / min / sec. */
export function DurationWheel({ seconds, onChange }: Props) {
  const theme = useThemeColors();
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;

  const itemStyle = { color: theme.ink, fontSize: 19 } as const;

  const update = (hours: number, minutes: number, secs: number) => {
    onChange(hours * 3600 + minutes * 60 + secs);
  };

  return (
    <View className="flex-row">
      <Picker
        style={{ flex: 1 }}
        itemStyle={itemStyle}
        selectedValue={h}
        onValueChange={(value) => update(value, m, s)}
      >
        {HOURS.map((value) => (
          <Picker.Item key={value} label={`${value} hr`} value={value} />
        ))}
      </Picker>
      <Picker
        style={{ flex: 1 }}
        itemStyle={itemStyle}
        selectedValue={m}
        onValueChange={(value) => update(h, value, s)}
      >
        {SIXTY.map((value) => (
          <Picker.Item key={value} label={`${value} min`} value={value} />
        ))}
      </Picker>
      <Picker
        style={{ flex: 1 }}
        itemStyle={itemStyle}
        selectedValue={s}
        onValueChange={(value) => update(h, m, value)}
      >
        {SIXTY.map((value) => (
          <Picker.Item key={value} label={`${value} sec`} value={value} />
        ))}
      </Picker>
    </View>
  );
}
