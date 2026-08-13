const STATUS_STYLES: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  paused: 'bg-amber-100 text-amber-700',
  disabled: 'bg-red-100 text-red-700',
  deleted: 'bg-gray-100 text-gray-500',
};

export default function StoreStatusBadge({ status }: { status: string }) {
  const style = STATUS_STYLES[status] ?? STATUS_STYLES.deleted;
  return (
    <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium capitalize ${style}`}>
      {status}
    </span>
  );
}
